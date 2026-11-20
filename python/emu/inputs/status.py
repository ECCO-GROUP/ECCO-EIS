"""`emu inputs status`: report a directory's download progress.

Reads, without changing anything: the release inventory (what should be
there), the state file (what has been verified), fetch_failures.txt
(the last run's failures), the lock file (whether a fetch may be
running) and the progress snapshot (its live counts, rate and ETA).
It can be run from any shell, including while a fetch is running.

Files are counted as in place only if the state file has verified them
with the inventory's md5; status doesn't re-check files on disk (that's
`emu inputs fetch --verify-only`).
"""

import json
import os
import socket

from emu.inputs.fetch import FAILURES_FILE, LOCK_FILE, STATE_FILE
from emu.inputs.progress import SNAPSHOT_FILE, format_hm
from emu.inputs.state import FetchState, _pid_is_alive

GB = 10**9
MB = 10**6


class Status:
    """Everything `emu inputs status` reports."""

    def __init__(self):
        self.files_total = 0
        self.bytes_total = 0
        self.files_done = 0
        self.bytes_done = 0
        self.failures = []     # (path, attempts text, error) from fetch_failures.txt
        self.lock = None       # lock file contents, if present
        self.running = None    # "running" if a fetch is running now, else None
        self.lock_note = None  # explanation when a lock is present but not live
        self.snapshot = None   # progress snapshot contents, if present


def collect_status(entries, root):
    """Gather a Status for `entries` (the selected inventory) in `root`."""
    s = Status()
    s.files_total = len(entries)
    s.bytes_total = sum(e.size for e in entries)

    # Files the state file has verified with the inventory's md5
    verified = FetchState(os.path.join(root, STATE_FILE)).load_verified()
    for e in entries:
        record = verified.get(e.path)
        if record is not None and record["md5"] == e.md5:
            s.files_done += 1
            s.bytes_done += e.size

    s.failures = _read_failures(os.path.join(root, FAILURES_FILE))
    s.snapshot = _read_json(os.path.join(root, SNAPSHOT_FILE))
    s.lock = _read_json(os.path.join(root, LOCK_FILE))

    # Is a fetch running now? Only checkable for a lock from this host
    if s.lock is not None:
        host, pid = s.lock.get("host"), s.lock.get("pid")
        if host != socket.gethostname():
            s.lock_note = (f"A fetch lock is held by pid {pid} on {host}; "
                           "can't tell from here whether it is still running.")
        elif _pid_is_alive(pid):
            s.running = "running"
        else:
            s.lock_note = "Not running (last run interrupted; its lock file was left behind)."

    # A running fetch's snapshot has newer counts (incl. in-progress bytes)
    if s.running and s.snapshot and s.snapshot.get("pid") == s.lock.get("pid"):
        s.files_done = s.snapshot.get("files_done", s.files_done)
        s.bytes_done = s.snapshot.get("bytes_done", s.bytes_done)
    return s


def format_status(s, description="the selected files"):
    """Format a Status as the text `emu inputs status` prints."""
    pct = round(100 * s.files_done / s.files_total) if s.files_total else 100
    if pct == 100 and s.files_done < s.files_total:
        pct = 99
    remaining_files = s.files_total - s.files_done
    remaining_bytes = max(s.bytes_total - s.bytes_done, 0)
    # The snapshot's mode says whether the run is a download or a verify;
    # snapshots from before modes existed were always downloads
    snap = s.snapshot
    mode = (snap or {}).get("mode", "fetch")
    still = "still to check" if s.running and mode == "verify" else "still to fetch"
    lines = [
        f"Status of {description}:",
        f"  {s.files_done:,}/{s.files_total:,} files ({pct}%) in place, "
        f"{s.bytes_done / GB:,.1f}/{s.bytes_total / GB:,.1f} GB",
        f"  {remaining_files:,} files ({remaining_bytes / GB:,.1f} GB) {still}",
    ]

    # Current or last run
    if s.running:
        parts = [f"{mode.capitalize()} running (pid {s.lock.get('pid')} on {s.lock.get('host')})"]
        if snap:
            parts.append(f"{snap.get('rate_bytes_per_s', 0) / MB:.0f} MB/s")
            eta = snap.get("eta_seconds")
            parts.append(f"ETA {format_hm(eta, round_up=True) if eta is not None else '--'}")
            if snap.get("retrying"):
                parts.append(f"{snap['retrying']} retrying")
            parts.append(f"updated {snap.get('updated')}")
        lines.append("  " + " · ".join(parts))
    elif s.lock_note:
        lines.append("  " + s.lock_note)
    elif snap:
        lines.append(f"  Last {mode} {snap.get('state', 'ended')} at {snap.get('updated')}.")
    elif s.files_done:
        # Verified files but no snapshot: worked on by an earlier version
        lines.append("  No progress record from the last run (it predates them).")
    else:
        lines.append("  No fetch has run in this directory yet.")
    if not s.running and s.files_done < s.files_total:
        # Files from a 1.2a install aren't in the state file until checked
        lines.append("  (Files already on disk but never fetched or verified by emu count "
                     "as still to fetch; `emu inputs fetch` checks them and skips good ones.)")

    # Last run's failures
    if s.failures:
        n = len(s.failures)
        lines.append(f"  {n} file{'s' if n != 1 else ''} failed in the last run:")
        for path, _, error in s.failures[:20]:
            lines.append(f"    {path}: {error}")
        if n > 20:
            lines.append(f"    ... and {n - 20} more (see {FAILURES_FILE})")
    return "\n".join(lines)


def _read_json(path):
    """Contents of a JSON file, or None if missing or unreadable."""
    try:
        with open(path) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


def _read_failures(path):
    """[(path, attempts, error)] from fetch_failures.txt, or []."""
    try:
        with open(path) as f:
            rows = [line.rstrip("\n").split("\t", 2) for line in f if line.strip()]
    except OSError:
        return []
    return [tuple(row + [""] * (3 - len(row))) for row in rows]
