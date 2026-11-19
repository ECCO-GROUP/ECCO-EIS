"""Download one input file with resume, md5 verification and retries.

transfer_file() handles a single inventory entry:
  1. Already recorded as verified in the state file, and the file on
     disk still has that size: skip, without contacting the server.
  2. Present on disk but not verified (e.g. a 1.2a input directory):
     md5 it. If correct, record it and skip; if not, move it aside to
     <path>.bad and download.
  3. Download into <path>.part, resuming an existing .part with a
     "Range: bytes=N-" request. A 206 reply is appended; a 200 reply
     means the server ignored Range, so the .part restarts from zero.
  4. When complete, the size and md5 must match the inventory; then the
     .part is renamed onto <path> and recorded as verified. A mismatch
     deletes the .part and counts as a failed attempt.
  5. Failed attempts are retried up to `tries` times, waiting 5, 10, 20,
     40, ... seconds (capped at 60) between them. Connection errors,
     timeouts, HTTP 5xx and size/md5 mismatches are retried; HTTP 401,
     403 and 404 fail at once, since retrying can't fix them.

Existing files may be symlinks (as in a linked input tree). They are
only read, never written: moving one aside moves the link, and the new
download replaces the link with a regular file, never its target.
"""

import base64
import hashlib
import http.client
import os
import socket
import time
import urllib.error
import urllib.request

# Result statuses
DOWNLOADED = "downloaded"
SKIPPED = "skipped"
VERIFIED_EXISTING = "verified_existing"
FAILED = "failed"

CHUNK = 1024 * 1024
PERMANENT_HTTP_ERRORS = {401, 403, 404}


class TransferResult:
    """Outcome of transfer_file for one entry."""

    def __init__(self, path, status, attempts=0, error=None):
        self.path = path
        self.status = status
        self.attempts = attempts
        self.error = error


class _RetryableError(Exception):
    """An attempt failed in a way a retry might fix."""


class _PermanentError(Exception):
    """An attempt failed in a way a retry can't fix."""


def backoff_seconds(failed_attempts):
    """Seconds to wait after the given number of failed attempts."""
    return min(5 * 2 ** (failed_attempts - 1), 60)


def md5_file(path, chunk=CHUNK):
    """Return the hex md5 of a file's contents (follows symlinks)."""
    digest = hashlib.md5()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(chunk), b""):
            digest.update(block)
    return digest.hexdigest()


def transfer_file(entry, url, root, state, verified, auth, tries=5,
                  timeout=60, sleep=time.sleep, opener=None):
    """Make <root>/<entry.path> a verified copy of the remote file.

    entry:    InventoryEntry (path, size, md5)
    url:      download URL for the entry
    root:     the emu_input_dir the entry's path is relative to
    state:    FetchState to record verified files in
    verified: dict from state.load_verified(), read once by the caller
    auth:     (username, password) for HTTP Basic auth
    sleep:    called with the backoff seconds between attempts
    opener:   urllib opener (default: urllib's normal one)
    """
    dest = os.path.join(root, entry.path)
    part = dest + ".part"

    # 1. Trust the state record only while the file still has its size
    record = verified.get(entry.path)
    if (record is not None and record["md5"] == entry.md5
            and _size_or_none(dest) == entry.size):
        return TransferResult(entry.path, SKIPPED)

    # 2. A file already present but not (or no longer) verified
    if os.path.lexists(dest):
        if _size_or_none(dest) == entry.size and md5_file(dest) == entry.md5:
            state.record_verified(entry.path, entry.size, entry.md5)
            return TransferResult(entry.path, VERIFIED_EXISTING)
        # os.replace on a symlink moves the link itself, not its target
        os.replace(dest, dest + ".bad")

    os.makedirs(os.path.dirname(dest), exist_ok=True)
    opener = opener or urllib.request.build_opener()
    token = base64.b64encode(f"{auth[0]}:{auth[1]}".encode()).decode()

    # 3–5. Download attempts with retries
    last_error = None
    for attempt in range(1, tries + 1):
        try:
            _download_attempt(url, part, entry, token, timeout, opener)
        except _PermanentError as error:
            return TransferResult(entry.path, FAILED, attempt, str(error))
        except _RetryableError as error:
            last_error = str(error)
            if attempt < tries:
                sleep(backoff_seconds(attempt))
            continue
        os.replace(part, dest)
        state.record_verified(entry.path, entry.size, entry.md5)
        return TransferResult(entry.path, DOWNLOADED, attempt)

    return TransferResult(entry.path, FAILED, tries, last_error)


def _download_attempt(url, part, entry, token, timeout, opener):
    """One attempt to complete <part>; raises _RetryableError or
    _PermanentError on failure, returns normally once the .part is
    complete and its md5 matches.
    """
    offset = os.path.getsize(part) if os.path.exists(part) else 0
    if offset > entry.size:
        os.remove(part)  # longer than the file can be: start over
        offset = 0

    if offset < entry.size:
        request = urllib.request.Request(url)
        request.add_header("Authorization", f"Basic {token}")
        if offset:
            request.add_header("Range", f"bytes={offset}-")
        try:
            response = opener.open(request, timeout=timeout)
        except urllib.error.HTTPError as error:
            error.close()
            if error.code in PERMANENT_HTTP_ERRORS:
                raise _PermanentError(f"HTTP {error.code} {error.reason} for {url}")
            if error.code == 416:
                # Range past the end: our .part must be wrong; restart
                os.remove(part)
                raise _RetryableError(f"HTTP 416 for {url}; restarting from zero")
            raise _RetryableError(f"HTTP {error.code} {error.reason} for {url}")
        except (urllib.error.URLError, OSError) as error:
            raise _RetryableError(f"cannot reach {url}: {error}")

        with response:
            # 206 continues the .part; 200 is the whole file from byte 0
            mode = "ab" if response.status == 206 and offset else "wb"
            try:
                with open(part, mode) as out:
                    for block in iter(lambda: response.read(CHUNK), b""):
                        out.write(block)
            except (http.client.IncompleteRead, socket.timeout, OSError) as error:
                raise _RetryableError(f"connection lost downloading {url}: {error}")

    # Check the completed .part; a bad one is discarded so the next
    # attempt starts from zero instead of resuming corrupt bytes
    size = os.path.getsize(part)
    if size != entry.size:
        if size > entry.size:
            os.remove(part)
        raise _RetryableError(f"size {size} != expected {entry.size} for {url}")
    actual = md5_file(part)
    if actual != entry.md5:
        os.remove(part)
        raise _RetryableError(f"md5 {actual} != expected {entry.md5} for {url}")


def _size_or_none(path):
    """Size of the file at path (following symlinks), or None if absent."""
    try:
        return os.path.getsize(path)
    except OSError:
        return None
