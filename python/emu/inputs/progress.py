"""Progress counters and reporting for a fetch.

Progress holds the shared counters the fetch workers update (files and
bytes done, failures, files waiting to retry, bytes received) under a
lock, plus a short history of samples for the transfer rate. Reporter
turns them into three outputs:

  - a live line, redrawn in place on a terminal:
      12,480/37,084 files (34%) · 61.2/181.5 GB · 48 MB/s · elapsed 0:21 · ETA 0:42 · 3 retrying
  - <root>/fetch_progress.log: the same line, timestamped, every
    `log_interval` seconds, plus a final summary line (for runs left
    going under nohup/screen)
  - <root>/.emu_fetch_progress.json: a snapshot of the counters,
    rewritten atomically every few seconds, for `emu inputs status`
"""

import collections
import json
import os
import socket
import threading
import time

PROGRESS_LOG = "fetch_progress.log"
SNAPSHOT_FILE = ".emu_fetch_progress.json"
RATE_WINDOW = 30.0  # seconds averaged over for the rate

GB = 10**9
MB = 10**6


class Progress:
    """Counters for one fetch, safe to update from many threads.

    bytes_done counts the size of finished (or already present) files
    plus the current size of each in-progress .part, so a large file's
    progress shows while it downloads. bytes_transferred counts bytes
    actually received from the network, which is what the rate uses.
    """

    def __init__(self, entries, clock=time.monotonic):
        self._lock = threading.Lock()
        self._clock = clock
        self.started = clock()
        self.files_total = len(entries)
        self.bytes_total = sum(e.size for e in entries)
        self.files_done = 0
        self.failed = 0
        self._finished_bytes = 0
        self._in_flight = {}  # path -> current .part size
        self._retrying = set()
        self.bytes_transferred = 0
        self._samples = collections.deque()  # (time, bytes_transferred)

    # ---- updates from workers ----

    def transferred(self, n):
        """Count n bytes received from the network."""
        with self._lock:
            self.bytes_transferred += n

    def part_size(self, path, size):
        """Record the current size of a file's in-progress .part."""
        with self._lock:
            self._in_flight[path] = size

    def retry_wait(self, path, waiting):
        """Mark a file as waiting to retry (True) or not (False)."""
        with self._lock:
            if waiting:
                self._retrying.add(path)
            else:
                self._retrying.discard(path)

    def finish(self, result, entry):
        """Record a file's TransferResult."""
        from emu.inputs.transfer import DOWNLOADED, FAILED, SKIPPED, VERIFIED_EXISTING

        with self._lock:
            self._in_flight.pop(entry.path, None)
            self._retrying.discard(entry.path)
            if result.status in (DOWNLOADED, SKIPPED, VERIFIED_EXISTING):
                self.files_done += 1
                self._finished_bytes += entry.size
            elif result.status == FAILED:
                self.failed += 1

    # ---- derived values ----

    @property
    def bytes_done(self):
        with self._lock:
            return self._finished_bytes + sum(self._in_flight.values())

    @property
    def retrying(self):
        with self._lock:
            return len(self._retrying)

    def sample(self):
        """Record (now, bytes_transferred) for the rate; drop samples
        older than the rate window (keeping one at its edge).
        """
        now = self._clock()
        with self._lock:
            self._samples.append((now, self.bytes_transferred))
            while len(self._samples) > 2 and self._samples[1][0] <= now - RATE_WINDOW:
                self._samples.popleft()

    def rate(self):
        """Bytes per second over the last RATE_WINDOW seconds (0 if unknown)."""
        with self._lock:
            if len(self._samples) < 2:
                return 0.0
            (t0, b0), (t1, b1) = self._samples[0], self._samples[-1]
        return (b1 - b0) / (t1 - t0) if t1 > t0 else 0.0

    def eta_seconds(self):
        """Seconds until done at the current rate, or None if the rate is 0.

        While any file is unfinished, at least one byte is counted as
        remaining, so a .part that has reached full size but is still
        being checked never makes the ETA read 0:00 early.
        """
        rate = self.rate()
        if rate <= 0:
            return None
        remaining = max(self.bytes_total - self.bytes_done, 0)
        if self.files_done + self.failed < self.files_total:
            remaining = max(remaining, 1)
        return remaining / rate

    def elapsed(self):
        return self._clock() - self.started

    def line(self):
        """The one-line progress summary."""
        files_done, files_total = self.files_done, self.files_total
        # Round to the nearest percent, but show 100% only when all done
        pct = round(100 * files_done / files_total) if files_total else 100
        if pct == 100 and files_done < files_total:
            pct = 99
        eta = self.eta_seconds()
        parts = [
            f"{files_done:,}/{files_total:,} files ({pct}%)",
            f"{self.bytes_done / GB:.1f}/{self.bytes_total / GB:.1f} GB",
            f"{self.rate() / MB:.0f} MB/s",
            f"elapsed {format_hm(self.elapsed())}",
            f"ETA {format_hm(eta, round_up=True) if eta is not None else '--'}",
        ]
        if self.retrying:
            parts.append(f"{self.retrying} retrying")
        if self.failed:
            parts.append(f"{self.failed} failed")
        return " · ".join(parts)

    def snapshot(self, state):
        """The counters as a dict, for the JSON snapshot file."""
        return {
            "state": state,
            "pid": os.getpid(),
            "host": socket.gethostname(),
            "updated": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "files_done": self.files_done,
            "files_total": self.files_total,
            "bytes_done": self.bytes_done,
            "bytes_total": self.bytes_total,
            "failed": self.failed,
            "retrying": self.retrying,
            "rate_bytes_per_s": self.rate(),
            "eta_seconds": self.eta_seconds(),
            "elapsed_seconds": self.elapsed(),
        }


def format_hm(seconds, round_up=False):
    """Format seconds as H:MM (hours:minutes)."""
    minutes = int(seconds // 60)
    if round_up and seconds % 60:
        minutes += 1
    return f"{minutes // 60}:{minutes % 60:02d}"


def is_foreground(stream):
    """Whether `stream` is a terminal and this process is in its
    foreground job (False after Ctrl-Z and `bg`, or with no terminal).
    """
    try:
        fd = stream.fileno()
        return os.isatty(fd) and os.tcgetpgrp(fd) == os.getpgrp()
    except (AttributeError, OSError, ValueError):
        return False


class Reporter:
    """Writes the live line, the progress log and the snapshot.

    Call tick() about once a second; it redraws the live line (only if
    `live` and the job is in the terminal's foreground, so a job put in
    the background with Ctrl-Z and `bg` doesn't write over the shell),
    appends to the log every `log_interval` seconds, and rewrites the
    snapshot every `snapshot_interval` seconds. Call close() once at the
    end for the final summary.
    """

    def __init__(self, progress, root, stream, live, log_interval=60,
                 snapshot_interval=5, foreground=None):
        self.progress = progress
        self.root = root
        self.stream = stream
        self.live = live
        self.log_interval = log_interval
        self.snapshot_interval = snapshot_interval
        self._foreground = foreground or (lambda: is_foreground(stream))
        self._clock = progress._clock
        self._last_log = None
        self._last_snapshot = None

    def _draw(self):
        # Draw the live line only when it won't write over a shell prompt
        return self.live and self._foreground()

    def tick(self):
        """Sample the rate and update whichever outputs are due."""
        now = self._clock()
        self.progress.sample()
        if self._draw():
            # \r returns to the start of the line; trailing spaces cover
            # any leftover characters from a longer previous line
            self.stream.write("\r" + self.progress.line() + "   ")
            self.stream.flush()
        if self._last_log is None or now - self._last_log >= self.log_interval:
            self._log(self.progress.line())
            self._last_log = now
        if self._last_snapshot is None or now - self._last_snapshot >= self.snapshot_interval:
            self._write_snapshot("running")
            self._last_snapshot = now

    def close(self, state, summary):
        """Write the final line, log entry and snapshot."""
        self.progress.sample()
        line = self.progress.line()
        if self._draw():
            self.stream.write("\r" + line + "   \n")
            self.stream.flush()
        self._log(line)
        self._log(f"{state}: {summary}")
        self._write_snapshot(state)

    def _log(self, text):
        stamp = time.strftime("%Y-%m-%d %H:%M:%S")
        with open(os.path.join(self.root, PROGRESS_LOG), "a") as f:
            f.write(f"{stamp} {text}\n")

    def _write_snapshot(self, state):
        # Write to a temporary file, then rename it into place: rename is
        # atomic, so a reader sees the old snapshot or the new one, never
        # a half-written file
        path = os.path.join(self.root, SNAPSHOT_FILE)
        tmp = f"{path}.tmp{os.getpid()}"
        with open(tmp, "w") as f:
            json.dump(self.progress.snapshot(state), f)
        os.replace(tmp, path)
