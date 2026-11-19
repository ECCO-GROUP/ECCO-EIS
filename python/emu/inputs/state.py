"""The fetch state file and the one-fetch-per-directory lock.

FetchState is an append-only JSON-lines record of which files in an
emu_input_dir have already been downloaded and md5-verified, so a
restart doesn't have to re-hash everything. Each record is one write to
a file opened O_APPEND, so a crash loses at most the line being written,
and threads in one process never interleave into one mangled line.
O_APPEND is not reliable between different NFS clients, so only one
process may write the record at a time; FetchLock enforces that.

FetchLock prevents two `emu inputs fetch` runs from touching the same
directory at once. The lock file is created atomically (O_CREAT|O_EXCL)
and holds the holder's PID and hostname. A lock whose PID is no longer
running on this host is stale and is taken over, with a warning. A lock
from another host, or one that can't be read, is refused, because this
host can't tell whether its holder is still running; the error names the
file so the user can remove it if they know the holder is gone.
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

        # O_APPEND keeps each short line intact between threads of this
        # process; cross-host safety on NFS comes from FetchLock instead.
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
                entry = {
                    "size": record["size"],
                    "md5": record["md5"],
                    "verified": record["verified"],
                }
                path = record["path"]
            except (json.JSONDecodeError, KeyError, TypeError):
                continue  # truncated, corrupt or incomplete line; skip it
            # A later line for the same path overrides an earlier one
            verified[path] = entry
        return verified


class FetchLock:
    """A lock file preventing two fetches in the same directory at once.

    Can be used directly (acquire()/release()) or as a context manager.
    """

    def __init__(self, path):
        self.path = path
        self._held = False

    def acquire(self):
        """Take the lock, raising LockHeldError if it may be held by a
        running process. A lock left by a dead PID on this host is
        stale and is taken over, with a warning.
        """
        if self._try_create():
            return

        holder = self._read_holder()
        if holder is None:
            raise LockHeldError(
                f"Fetch lock {self.path} exists but can't be read (it may be "
                "being written right now, or be left from a crash). If no "
                "fetch is running in this directory, remove it and retry."
            )
        host, pid = holder.get("host"), holder.get("pid")
        if host != socket.gethostname():
            raise LockHeldError(
                f"Fetch lock {self.path} is held by pid {pid} on host {host}, "
                "which can't be checked from here. If no fetch is running "
                "there, remove the lock file and retry."
            )
        if _pid_is_alive(pid):
            raise LockHeldError(
                f"Fetch lock {self.path} is held by running pid {pid} on {host}; "
                "refusing to start a second fetch in this directory."
            )

        # Same host, dead PID: stale. Remove it and retry the atomic
        # create, so a racing process can't also take it over.
        warnings.warn(
            f"Taking over stale fetch lock {self.path} "
            f"(pid {pid} on {host} is no longer running)",
            UserWarning,
        )
        try:
            os.remove(self.path)
        except FileNotFoundError:
            pass
        if not self._try_create():
            raise LockHeldError(
                f"Fetch lock {self.path} was taken by another process while "
                "removing a stale lock; refusing to start."
            )

    def release(self):
        """Remove the lock file, but only if it is still ours."""
        if self._held and self._read_holder() == self._identity():
            try:
                os.remove(self.path)
            except FileNotFoundError:
                pass
        self._held = False

    def _identity(self):
        # What this process writes into the lock file
        return {"pid": os.getpid(), "host": socket.gethostname()}

    def _try_create(self):
        """Atomically create the lock file with our identity; return
        False if it already exists.
        """
        try:
            fd = os.open(self.path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
        except FileExistsError:
            return False
        try:
            os.write(fd, json.dumps(self._identity()).encode("utf-8"))
        finally:
            os.close(fd)
        self._held = True
        return True

    def _read_holder(self):
        """Return the lock file's {"pid", "host"} dict, or None if the
        file is missing, empty or not a valid lock record.
        """
        try:
            with open(self.path) as f:
                holder = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return None
        if not isinstance(holder, dict) or "pid" not in holder or "host" not in holder:
            return None
        return holder

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
