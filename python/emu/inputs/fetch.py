"""Download many inventory entries in parallel and report failures.

fetch() takes the fetch lock for the input directory, reads the state
file once, and runs transfer_file() for each entry on a bounded pool of
`jobs` worker threads, so at most `jobs` downloads are in progress at
once. Each failure is collected rather than stopping the run, so every
other file still gets its chance. At the end the failures are written to
<root>/fetch_failures.txt (removed after a clean run), and the summary's
exit_code is 0 if every entry is in place and 1 otherwise.

Ctrl-C sets a stop event: running transfers end at their next chunk,
keeping their .part files and every verified file already recorded, no
new transfers start, and the lock is released, so the same command can
simply be run again to carry on.

While it runs, a reporter thread ticks about once a second, updating
the live progress line (on a terminal), fetch_progress.log and the
.emu_fetch_progress.json snapshot (see progress.py).
"""

import os
import queue
import shutil
import subprocess
import sys
import threading
import time

from emu.inputs.progress import Progress, Reporter
from emu.inputs.state import FetchLock, FetchState
from emu.inputs.transfer import (
    DOWNLOADED,
    FAILED,
    INTERRUPTED,
    SKIPPED,
    VERIFIED_EXISTING,
    TransferResult,
    md5_file,
    transfer_file,
)

EXIT_OK = 0
EXIT_FAILURES = 1

STATE_FILE = ".emu_fetch_state"
LOCK_FILE = ".emu_fetch.lock"
FAILURES_FILE = "fetch_failures.txt"


class FetchSummary:
    """Totals for one fetch run."""

    def __init__(self):
        self.downloaded = 0
        self.skipped = 0
        self.verified_existing = 0
        self.failed = []  # TransferResult for each failed entry
        self.interrupted = False
        self.not_attempted = 0

    @property
    def exit_code(self):
        if self.failed or self.interrupted or self.not_attempted:
            return EXIT_FAILURES
        return EXIT_OK


def fetch(entries, url_for, root, auth, jobs=8, tries=5, timeout=60,
          sleep=None, opener=None, stop=None, on_result=None,
          progress_stream=None, live=None, tick_seconds=1.0, log_interval=60,
          foreground=None):
    """Bring every entry under `root` up to date; return a FetchSummary.

    entries:         InventoryEntry list (from manifest.select_entries)
    url_for:         function mapping an entry's path to its download URL
    root:            the emu_input_dir
    auth:            (username, password)
    jobs:            maximum number of downloads in progress at once
    stop:            threading.Event; set it (e.g. on Ctrl-C) to wind down
    on_result:       called with each TransferResult as it finishes
    progress_stream: where the live line goes (default sys.stderr)
    live:            draw the live line (default: if the stream is a tty)
    tick_seconds:    how often progress is updated
    log_interval:    seconds between fetch_progress.log lines
    foreground:      function telling whether to draw the live line now
                     (default: whether the job is in the terminal foreground)

    Raises state.LockHeldError if another fetch holds the directory.
    """
    os.makedirs(root, exist_ok=True)
    stop = stop or threading.Event()
    summary = FetchSummary()
    summary_lock = threading.Lock()
    stream = progress_stream if progress_stream is not None else sys.stderr
    if live is None:
        live = hasattr(stream, "isatty") and stream.isatty()

    with FetchLock(os.path.join(root, LOCK_FILE)):
        state = FetchState(os.path.join(root, STATE_FILE))
        verified = state.load_verified()
        progress = Progress(entries)
        reporter = Reporter(progress, root, stream, live, log_interval=log_interval,
                            foreground=foreground)

        # Work queue of entries; each worker takes the next until empty
        work = queue.Queue()
        for entry in entries:
            work.put(entry)

        def worker():
            while not stop.is_set():
                try:
                    entry = work.get_nowait()
                except queue.Empty:
                    return
                try:
                    result = transfer_file(
                        entry, url_for(entry.path), root, state, verified, auth,
                        tries=tries, timeout=timeout, sleep=sleep, opener=opener,
                        stop=stop, progress=progress,
                    )
                except Exception as error:
                    # Anything transfer_file doesn't handle itself (permission
                    # denied, disk full, ...) fails this file, not the worker
                    result = TransferResult(entry.path, FAILED, 0,
                                            f"unexpected error: {error}")
                with summary_lock:
                    _count(summary, result)
                progress.finish(result, entry)
                if on_result is not None:
                    on_result(result)

        # Reporter thread: updates the progress outputs every tick
        workers_done = threading.Event()

        def report():
            while not workers_done.wait(tick_seconds):
                reporter.tick()

        threads = [threading.Thread(target=worker, daemon=True)
                   for _ in range(max(1, min(jobs, len(entries))))]
        reporter.tick()
        reporter_thread = threading.Thread(target=report, daemon=True)
        reporter_thread.start()
        for t in threads:
            t.start()
        try:
            # Join in short slices so Ctrl-C reaches this (main) thread
            for t in threads:
                while t.is_alive():
                    t.join(timeout=0.2)
        except KeyboardInterrupt:
            stop.set()
            for t in threads:
                t.join()
            summary.interrupted = True
        finally:
            workers_done.set()
            reporter_thread.join()

        if stop.is_set():
            summary.interrupted = True
        summary.not_attempted = work.qsize()
        reporter.close("interrupted" if summary.interrupted else "finished",
                       _summary_text(summary))

    _write_failures(root, summary)
    return summary


POSTPROCESS_LOG = "postprocess.log"

# postprocess() outcomes
POSTPROCESS_NOT_NEEDED = "not needed"     # no rule, or its tool isn't selected
POSTPROCESS_EXISTS = "already done"       # the directory it creates exists
POSTPROCESS_INCOMPLETE = "inputs incomplete"
POSTPROCESS_DONE = "done"
POSTPROCESS_FAILED = "failed"


class PostprocessResult:
    """Outcome of postprocess(): one of the POSTPROCESS_* statuses."""

    def __init__(self, status, message=""):
        self.status = status
        self.message = message


def postprocess(release, entries, root, tools=None, select_all=False):
    """Run the release's post-fetch step if it is needed and possible.

    For v4r4-llc90-flux this is 1.2a's emu_input_install.sh step for the
    Tracer Tool: once state_weekly and scripts are in place, symlink
    scripts/* into forcing/other/flux-forced and run reverseintime_all.sh
    there, which builds state_weekly_rev_time_227808 (links to the
    weekly files in reverse time order, for the adjoint tracer).

    It runs only if the rule's tool is selected (or select_all), the
    directory it creates doesn't exist yet, and every selected file under
    its `requires` paths is recorded as verified. Output goes to
    <root>/postprocess.log. If the script fails, whatever it created is
    moved to <creates>.incomplete so a rerun tries again.
    """
    rule = release.postprocess
    if not rule or not (select_all or rule["tool"] in (tools or [])):
        return PostprocessResult(POSTPROCESS_NOT_NEEDED)
    # Absolute, so the links made below still resolve from the workdir
    root = os.path.abspath(root)

    creates = os.path.join(root, rule["creates"])
    if os.path.lexists(creates):
        return PostprocessResult(POSTPROCESS_EXISTS, f"{rule['creates']} already exists")

    # Every required input must be verified (a failed or partial fetch
    # leaves some unverified, and the script would build a broken tree)
    verified = FetchState(os.path.join(root, STATE_FILE)).load_verified()
    needed = [e for e in entries
              if any(e.path == p or e.path.startswith(p + "/") for p in rule["requires"])]
    missing = [e.path for e in needed
               if verified.get(e.path, {}).get("md5") != e.md5]
    if missing or not needed:
        return PostprocessResult(
            POSTPROCESS_INCOMPLETE,
            f"{len(missing)} required file(s) not yet in place, e.g. {missing[0]}" if missing
            else "no required files selected")

    script = os.path.join(root, rule["scripts_dir"], rule["script"])
    if not os.path.isfile(script):
        return PostprocessResult(POSTPROCESS_FAILED, f"{script} not found")

    # As 1.2a: link each scripts/* file into the work directory, then run
    # the script there with bash (ln -sf: replace any existing link)
    workdir = os.path.join(root, rule["workdir"])
    scripts_dir = os.path.join(root, rule["scripts_dir"])
    for name in sorted(os.listdir(scripts_dir)):
        link = os.path.join(workdir, name)
        if os.path.islink(link):
            os.remove(link)
        if not os.path.exists(link):
            os.symlink(os.path.join(scripts_dir, name), link)

    log_path = os.path.join(root, POSTPROCESS_LOG)
    with open(log_path, "a") as log:
        log.write(f"--- {time.strftime('%Y-%m-%d %H:%M:%S')} running {rule['script']} "
                  f"in {workdir}\n")
        log.flush()
        proc = subprocess.run(["bash", rule["script"]], cwd=workdir,
                              stdout=log, stderr=subprocess.PIPE, text=True)
        log.write(proc.stderr)
        log.write(f"--- exit status {proc.returncode}\n")

    if proc.returncode != 0:
        if os.path.lexists(creates):
            aside = creates + ".incomplete"
            if os.path.lexists(aside):
                shutil.rmtree(aside)  # an earlier failed attempt's leftovers
            os.replace(creates, aside)
        last = proc.stderr.strip().splitlines()[-1] if proc.stderr.strip() else ""
        return PostprocessResult(
            POSTPROCESS_FAILED, f"{rule['script']} exited {proc.returncode}: {last}")
    return PostprocessResult(POSTPROCESS_DONE, f"built {rule['creates']}")


VERIFY_FAILURES_FILE = "verify_failures.txt"

# verify() outcomes per file
OK, MISSING, WRONG_SIZE, WRONG_MD5 = "ok", "missing", "wrong size", "wrong md5"
ERROR = "error"  # the check itself failed (e.g. an I/O error reading the file)


class VerifySummary:
    """Totals for one verify run."""

    def __init__(self):
        self.ok = 0
        self.missing = []
        self.wrong_size = []
        self.wrong_md5 = []
        self.errors = []  # (entry, message) for checks that raised
        self.interrupted = False

    @property
    def problems(self):
        return (len(self.missing) + len(self.wrong_size) + len(self.wrong_md5)
                + len(self.errors))

    @property
    def exit_code(self):
        return EXIT_FAILURES if self.problems or self.interrupted else EXIT_OK


def check_file(entry, root):
    """Check one file on disk against the inventory, following symlinks
    without changing anything: return OK, MISSING, WRONG_SIZE or WRONG_MD5.
    """
    path = os.path.join(root, entry.path)
    try:
        size = os.path.getsize(path)
    except OSError:
        return MISSING
    if size != entry.size:
        return WRONG_SIZE
    return OK if md5_file(path) == entry.md5 else WRONG_MD5


def verify(entries, root, jobs=4, stop=None, on_result=None, progress_stream=None,
           live=None, tick_seconds=1.0, log_interval=60, foreground=None):
    """Re-check every entry's file in `root` against the inventory,
    without network access and ignoring the state file; record good
    files as verified and forget bad ones. Returns a VerifySummary and
    writes problems to <root>/verify_failures.txt (removed if none).

    on_result: called with (path, outcome) for each file checked.
    The progress options are as for fetch(); the live line, the log
    and the snapshot (mode "verify") let `emu inputs status` show the
    check's rate and ETA.
    Raises state.LockHeldError if a fetch holds the directory.
    """
    stop = stop or threading.Event()
    summary = VerifySummary()
    summary_lock = threading.Lock()
    stream = progress_stream if progress_stream is not None else sys.stderr
    if live is None:
        live = hasattr(stream, "isatty") and stream.isatty()

    with FetchLock(os.path.join(root, LOCK_FILE)):
        state = FetchState(os.path.join(root, STATE_FILE))
        progress = Progress(entries, mode="verify")
        reporter = Reporter(progress, root, stream, live, log_interval=log_interval,
                            foreground=foreground)
        work = queue.Queue()
        for entry in entries:
            work.put(entry)

        def worker():
            # Check files until the queue is empty or Ctrl-C
            while not stop.is_set():
                try:
                    entry = work.get_nowait()
                except queue.Empty:
                    return
                try:
                    outcome = check_file(entry, root)
                except Exception as error:
                    # e.g. an I/O error reading the file: report it, keep going
                    state.forget(entry.path)
                    progress.checked(entry, False, 0)
                    with summary_lock:
                        summary.errors.append((entry, str(error)))
                    if on_result is not None:
                        on_result(entry.path, ERROR)
                    continue
                # A file checked for md5 was read in full; others weren't
                read = entry.size if outcome in (OK, WRONG_MD5) else 0
                progress.checked(entry, outcome == OK, read)
                if outcome == OK:
                    state.record_verified(entry.path, entry.size, entry.md5)
                else:
                    state.forget(entry.path)
                with summary_lock:
                    if outcome == OK:
                        summary.ok += 1
                    else:
                        {MISSING: summary.missing, WRONG_SIZE: summary.wrong_size,
                         WRONG_MD5: summary.wrong_md5}[outcome].append(entry)
                if on_result is not None:
                    on_result(entry.path, outcome)

        # Reporter thread: updates the progress outputs every tick
        workers_done = threading.Event()

        def report():
            while not workers_done.wait(tick_seconds):
                reporter.tick()

        threads = [threading.Thread(target=worker, daemon=True)
                   for _ in range(max(1, min(jobs, len(entries))))]
        reporter.start()
        reporter.tick()
        reporter_thread = threading.Thread(target=report, daemon=True)
        reporter_thread.start()
        for t in threads:
            t.start()
        try:
            for t in threads:
                while t.is_alive():
                    t.join(timeout=0.2)
        except KeyboardInterrupt:
            stop.set()
            for t in threads:
                t.join()
        finally:
            workers_done.set()
            reporter_thread.join()
        summary.interrupted = stop.is_set()
        reporter.close("interrupted" if summary.interrupted else "finished",
                       f"{summary.ok} correct, {len(summary.missing)} missing, "
                       f"{len(summary.wrong_size)} wrong size, {len(summary.wrong_md5)} wrong md5")

    # Report problems by category, or remove an old report after a clean run
    report = os.path.join(root, VERIFY_FAILURES_FILE)
    rows = [(MISSING, e) for e in summary.missing] + \
           [(WRONG_SIZE, e) for e in summary.wrong_size] + \
           [(WRONG_MD5, e) for e in summary.wrong_md5] + \
           [(ERROR, e) for e, _ in summary.errors]
    if rows:
        with open(report, "w") as f:
            for category, e in sorted(rows, key=lambda r: (r[0], r[1].path)):
                f.write(f"{category}\t{e.path}\n")
    elif not summary.interrupted and os.path.exists(report):
        os.remove(report)
    return summary


def _summary_text(summary):
    """One-line totals for the end of the progress log."""
    text = (f"{summary.downloaded} downloaded, "
            f"{summary.skipped + summary.verified_existing} skipped, "
            f"{len(summary.failed)} failed")
    if summary.not_attempted:
        text += f", {summary.not_attempted} not attempted"
    return text


def _count(summary, result):
    """Add one TransferResult to the summary totals."""
    if result.status == DOWNLOADED:
        summary.downloaded += 1
    elif result.status == SKIPPED:
        summary.skipped += 1
    elif result.status == VERIFIED_EXISTING:
        summary.verified_existing += 1
    elif result.status == FAILED:
        summary.failed.append(result)
    elif result.status == INTERRUPTED:
        summary.not_attempted += 1


def _write_failures(root, summary):
    """Write <root>/fetch_failures.txt listing each failed file and why,
    or remove an old one after a run with no failures.
    """
    path = os.path.join(root, FAILURES_FILE)
    if not summary.failed:
        if not summary.interrupted and os.path.exists(path):
            os.remove(path)
        return
    with open(path, "w") as f:
        for result in sorted(summary.failed, key=lambda r: r.path):
            f.write(f"{result.path}\t{result.attempts} attempt(s)\t{result.error}\n")
