"""Tests for emu.inputs.state: the verified-files record (FetchState)
and the one-fetch-per-directory lock (FetchLock).
"""

import json
import os
import threading

import pytest

from emu.inputs.state import FetchLock, FetchState, LockHeldError


# ---- FetchState: recording and reloading verified files ----

def test_record_and_reload_verified_entry(tmp_path):
    state = FetchState(tmp_path / ".emu_fetch_state")
    state.record_verified("emu_ref/XC.data", size=100, md5="aaaa")

    verified = FetchState(tmp_path / ".emu_fetch_state").load_verified()
    assert "emu_ref/XC.data" in verified
    assert verified["emu_ref/XC.data"]["size"] == 100
    assert verified["emu_ref/XC.data"]["md5"] == "aaaa"
    assert "verified" in verified["emu_ref/XC.data"]  # a timestamp was recorded


def test_load_verified_on_missing_file_returns_empty(tmp_path):
    # A fetch that has never run yet has no state file; that's not an error.
    state = FetchState(tmp_path / ".emu_fetch_state")
    assert state.load_verified() == {}


def test_truncated_last_line_is_ignored(tmp_path):
    # A crash mid-write can leave a partial JSON line at the end of the
    # file; it must be ignored, not raise, and must not lose the lines
    # written before it.
    state_path = tmp_path / ".emu_fetch_state"
    state_path.write_text(
        '{"path": "a.data", "size": 1, "md5": "x", "verified": "t"}\n'
        '{"path": "b.data", "size": 2, "md5'  # truncated mid-write
    )
    verified = FetchState(state_path).load_verified()
    assert verified.keys() == {"a.data"}


def test_later_entry_for_same_path_overrides_earlier_one(tmp_path):
    # Re-verifying a file (e.g. after a repair) appends a new line rather
    # than editing the old one; the newest entry for a path must win.
    state_path = tmp_path / ".emu_fetch_state"
    state = FetchState(state_path)
    state.record_verified("x.data", size=100, md5="old")
    state.record_verified("x.data", size=100, md5="new")

    verified = FetchState(state_path).load_verified()
    assert verified["x.data"]["md5"] == "new"


def test_concurrent_appends_from_threads_do_not_interleave(tmp_path):
    # Many threads recording different files at once must each produce
    # one intact JSON line; no line may be a mangled mix of two entries.
    state = FetchState(tmp_path / ".emu_fetch_state")
    n = 50

    def record(i):
        state.record_verified(f"file{i}.data", size=i, md5=f"md5-{i}")

    threads = [threading.Thread(target=record, args=(i,)) for i in range(n)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    verified = state.load_verified()
    assert len(verified) == n
    for i in range(n):
        assert verified[f"file{i}.data"]["md5"] == f"md5-{i}"


# ---- FetchLock: one fetch at a time per directory ----

def test_lock_can_be_acquired_and_released(tmp_path):
    lock = FetchLock(tmp_path / ".emu_fetch.lock")
    lock.acquire()
    lock.release()
    # Released lock file is gone, so a second acquire succeeds too
    lock.acquire()
    lock.release()


def test_lock_refused_when_held_by_a_live_pid(tmp_path):
    lock_path = tmp_path / ".emu_fetch.lock"
    # This test process's own PID is, by definition, alive right now.
    lock_path.write_text(json.dumps({"pid": os.getpid(), "host": _hostname()}))

    with pytest.raises(LockHeldError):
        FetchLock(lock_path).acquire()


def test_stale_lock_from_dead_pid_is_taken_over_with_a_warning(tmp_path):
    lock_path = tmp_path / ".emu_fetch.lock"
    dead_pid = _find_a_dead_pid()
    lock_path.write_text(json.dumps({"pid": dead_pid, "host": _hostname()}))

    with pytest.warns(UserWarning, match=str(dead_pid)):
        FetchLock(lock_path).acquire()

    # The lock file now reflects this process, not the stale one
    held = json.loads(lock_path.read_text())
    assert held["pid"] == os.getpid()


def test_lock_as_context_manager_releases_on_exit(tmp_path):
    lock_path = tmp_path / ".emu_fetch.lock"
    with FetchLock(lock_path):
        assert lock_path.exists()
    assert not lock_path.exists()


def _hostname():
    import socket

    return socket.gethostname()


def _find_a_dead_pid():
    # Search downward from a very large PID for one that doesn't exist;
    # far more reliable across machines than hard-coding a number.
    for candidate in range(2**22, 2, -1):
        try:
            os.kill(candidate, 0)
        except ProcessLookupError:
            return candidate
        except PermissionError:
            continue  # exists, but we can't signal it; keep looking
    pytest.fail("could not find an unused PID to test with")
