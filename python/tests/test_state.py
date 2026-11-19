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


def test_forget_removes_a_verified_record(tmp_path):
    # The file stays append-only: forgetting appends a record that cancels
    # earlier ones, and a later record_verified() restores the entry.
    state_path = tmp_path / ".emu_fetch_state"
    state = FetchState(state_path)
    state.record_verified("x.data", size=1, md5="a")
    state.record_verified("y.data", size=2, md5="b")
    state.forget("x.data")
    assert FetchState(state_path).load_verified().keys() == {"y.data"}
    state.record_verified("x.data", size=1, md5="a")
    assert FetchState(state_path).load_verified().keys() == {"x.data", "y.data"}


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


def test_lock_held_by_another_host_is_refused_not_taken_over(tmp_path):
    # The input directory is on shared NFS; a PID from another host can't
    # be checked from here, so the lock must be refused (that fetch may
    # still be running), and left untouched.
    lock_path = tmp_path / ".emu_fetch.lock"
    other = {"pid": 12345, "host": "some-other-host.example"}
    lock_path.write_text(json.dumps(other))

    with pytest.raises(LockHeldError) as exc_info:
        FetchLock(lock_path).acquire()
    message = str(exc_info.value)
    assert "some-other-host.example" in message
    assert str(lock_path) in message  # tells the user which file to remove
    assert json.loads(lock_path.read_text()) == other


def test_empty_or_corrupt_lock_file_is_reported_not_crashed_on(tmp_path):
    # A crash between creating and writing the lock leaves an empty file.
    # It can't be told apart from a lock being written right now, so it is
    # refused with a clear message, not a raw JSONDecodeError.
    lock_path = tmp_path / ".emu_fetch.lock"
    for content in ["", "not json", "[1, 2]"]:
        lock_path.write_text(content)
        with pytest.raises(LockHeldError) as exc_info:
            FetchLock(lock_path).acquire()
        assert str(lock_path) in str(exc_info.value)


def test_simultaneous_acquires_let_exactly_one_win(tmp_path):
    # Many threads racing to acquire the same lock: creation must be a
    # single atomic step, so exactly one succeeds and the rest are refused.
    lock_path = tmp_path / ".emu_fetch.lock"
    results = []
    barrier = threading.Barrier(20)

    def try_acquire():
        lock = FetchLock(lock_path)
        barrier.wait()
        try:
            lock.acquire()
            results.append("won")
        except LockHeldError:
            results.append("refused")

    threads = [threading.Thread(target=try_acquire) for _ in range(20)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    assert results.count("won") == 1
    assert results.count("refused") == 19


def test_release_does_not_remove_a_lock_now_owned_by_someone_else(tmp_path):
    # If another process took the lock over after we acquired it, our
    # release must leave their lock file alone.
    lock_path = tmp_path / ".emu_fetch.lock"
    lock = FetchLock(lock_path)
    lock.acquire()
    takeover = {"pid": 12345, "host": "some-other-host.example"}
    lock_path.write_text(json.dumps(takeover))

    lock.release()
    assert json.loads(lock_path.read_text()) == takeover


def test_valid_json_record_missing_a_field_is_skipped(tmp_path):
    state_path = tmp_path / ".emu_fetch_state"
    state_path.write_text(
        '{"path": "a.data", "size": 1, "md5": "x", "verified": "t"}\n'
        '{"path": "b.data"}\n'
        '["not", "a", "record"]\n'
    )
    assert FetchState(state_path).load_verified().keys() == {"a.data"}


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
