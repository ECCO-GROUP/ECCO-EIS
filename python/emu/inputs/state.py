"""The fetch state file and the one-fetch-per-directory lock.

FetchState is an append-only JSON-lines record of which files in an
emu_input_dir have already been downloaded and md5-verified, so a
restart doesn't have to re-hash everything. Each append is a single
atomic write (os.write to a file opened O_APPEND), so a crash loses at
most the line being written, and concurrent writers from different
threads never interleave into one mangled line.

FetchLock prevents two `emu inputs fetch` runs from touching the same
directory at once. The lock file holds the holder's PID and hostname; a
lock whose PID is no longer running on this host is stale and is
silently taken over (with a warning), since it must be left over from a
process that crashed rather than one that is still fetching.
"""

import json
import os
import socket
import time
import warnings


class LockHeldError(Exception):
    """Raised when a fetch directory's lock is held by a live process."""


class FetchState:
    """Tracks which files, under one emu_input_dir, are known-good."""

    def __init__(self, path):
        self.path = path

    def record_verified(self, rel_path, size, md5):
        """Append one verified-file record. Safe to call concurrently
        from multiple threads: each call is a single atomic append.
        """
        record = {
            "path": rel_path,
            "size": size,
            "md5": md5,
            "verified": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        }
        line = (json.dumps(record) + "\n").encode("utf-8")

        # Open in append mode so concurrent writers from different
        # threads/processes are serialized by the OS; os.write of a
        # single short line is atomic on a local or NFS filesystem.
        fd = os.open(self.path, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o644)
        try:
            os.write(fd, line)
        finally:
            os.close(fd)

    def load_verified(self):
        """Return {path: {"size", "md5", "verified"}} for every file
        whose newest recorded entry is intact. A truncated last line
        (from a crash mid-write) is ignored, not an error.
        """
        if not os.path.exists(self.path):
            return {}

        verified = {}
        with open(self.path) as f:
            lines = f.readlines()
        for line in lines:
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue  # truncated or corrupt line; skip it
            # A later line for the same path overrides an earlier one,
            # since dict assignment here just replaces any prior value.
            verified[record["path"]] = {
                "size": record["size"],
                "md5": record["md5"],
                "verified": record["verified"],
            }
        return verified


class FetchLock:
    """A lock file preventing two fetches in the same directory at once.

    Can be used directly (acquire()/release()) or as a context manager.
    """

    def __init__(self, path):
        self.path = path
        self._held = False

    def acquire(self):
        """Take the lock, raising LockHeldError if another live process
        already holds it. A lock left by a process that is no longer
        running (same host) is stale and is taken over, with a warning.
        """
        if os.path.exists(self.path):
            with open(self.path) as f:
                holder = json.load(f)
            if holder.get("host") == socket.gethostname() and _pid_is_alive(holder.get("pid")):
                raise LockHeldError(
                    f"Fetch lock {self.path} is held by pid {holder['pid']} "
                    f"on {holder['host']}; refusing to start a second fetch "
                    "in this directory."
                )
            # Different host, or same host but the PID is dead: stale.
            warnings.warn(
                f"Taking over stale fetch lock {self.path} "
                f"(held by pid {holder.get('pid')} on {holder.get('host')}, "
                "no longer running)",
                UserWarning,
            )

        with open(self.path, "w") as f:
            json.dump({"pid": os.getpid(), "host": socket.gethostname()}, f)
        self._held = True

    def release(self):
        if self._held and os.path.exists(self.path):
            os.remove(self.path)
        self._held = False

    def __enter__(self):
        self.acquire()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.release()


def _pid_is_alive(pid):
    """Return whether a process with this pid is currently running."""
    if pid is None:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True  # exists, just owned by someone else
    return True
