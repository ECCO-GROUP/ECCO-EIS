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
"""

import os
import queue
import threading

from emu.inputs.state import FetchLock, FetchState
from emu.inputs.transfer import (
    DOWNLOADED,
    FAILED,
    INTERRUPTED,
    SKIPPED,
    VERIFIED_EXISTING,
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
          sleep=None, opener=None, stop=None, on_result=None):
    """Bring every entry under `root` up to date; return a FetchSummary.

    entries:   InventoryEntry list (from manifest.select_entries)
    url_for:   function mapping an entry's path to its download URL
    root:      the emu_input_dir
    auth:      (username, password)
    jobs:      maximum number of downloads in progress at once
    stop:      threading.Event; set it (e.g. on Ctrl-C) to wind down early
    on_result: called with each TransferResult as it finishes (progress)

    Raises state.LockHeldError if another fetch holds the directory.
    """
    os.makedirs(root, exist_ok=True)
    stop = stop or threading.Event()
    summary = FetchSummary()
    summary_lock = threading.Lock()

    with FetchLock(os.path.join(root, LOCK_FILE)):
        state = FetchState(os.path.join(root, STATE_FILE))
        verified = state.load_verified()

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
                result = transfer_file(
                    entry, url_for(entry.path), root, state, verified, auth,
                    tries=tries, timeout=timeout, sleep=sleep, opener=opener,
                    stop=stop,
                )
                with summary_lock:
                    _count(summary, result)
                if on_result is not None:
                    on_result(result)

        threads = [threading.Thread(target=worker, daemon=True)
                   for _ in range(max(1, min(jobs, len(entries))))]
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

        if stop.is_set():
            summary.interrupted = True
        summary.not_attempted = work.qsize()

    _write_failures(root, summary)
    return summary


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
