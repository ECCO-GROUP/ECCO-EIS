"""Tests for emu.inputs.transfer: downloading one file with resume,
md5 verification and retries, against the fake ECCO Drive server.
"""

import hashlib
import os
import urllib.request

import pytest

from emu.inputs.manifest import InventoryEntry
from emu.inputs.state import FetchState
from emu.inputs.transfer import (
    DOWNLOADED,
    FAILED,
    SKIPPED,
    VERIFIED_EXISTING,
    backoff_seconds,
    md5_file,
    transfer_file,
)

CONTENT = bytes(range(256)) * 400  # 102,400 bytes
PATH = "emu_ref/diags/XC.data"


@pytest.fixture
def setup(drive_server, tmp_path):
    """Serve one file and return everything transfer_file needs."""
    drive_server.add_file(PATH, CONTENT)
    entry = InventoryEntry(PATH, len(CONTENT), hashlib.md5(CONTENT).hexdigest())
    root = tmp_path / "inputs"
    root.mkdir()
    state = FetchState(root / ".emu_fetch_state")
    sleeps = []

    class Setup:
        server = drive_server
        dest = root / PATH
        part = root / (PATH + ".part")
        bad = root / (PATH + ".bad")

        def run(self, tries=5, verified=None):
            # Proxy-free opener so test requests always reach the local server
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
            return transfer_file(
                entry, drive_server.url(PATH), root, state,
                verified if verified is not None else state.load_verified(),
                (drive_server.username, drive_server.password),
                tries=tries, sleep=sleeps.append, opener=opener,
            )

    s = Setup()
    s.entry, s.root, s.state, s.sleeps = entry, root, state, sleeps
    return s


def _statuses(server):
    return [(r.range_header, r.status) for r in server.requests]


# ---- success paths ----

def test_clean_download(setup):
    result = setup.run()
    assert result.status == DOWNLOADED
    assert result.attempts == 1
    assert setup.dest.read_bytes() == CONTENT
    assert not setup.part.exists()
    assert PATH in setup.state.load_verified()
    assert setup.sleeps == []


def test_dropped_connection_resumes_with_range(setup):
    setup.server.set_fault(PATH, drop_after=1000, times=1)
    result = setup.run()
    assert result.status == DOWNLOADED
    assert result.attempts == 2
    assert setup.dest.read_bytes() == CONTENT
    # First request has no Range; the retry asks for the rest only
    assert _statuses(setup.server) == [(None, 200), ("bytes=1000-", 206)]
    assert setup.sleeps == [5]


def test_existing_part_file_is_resumed(setup):
    setup.part.parent.mkdir(parents=True)
    setup.part.write_bytes(CONTENT[:5000])
    result = setup.run()
    assert result.status == DOWNLOADED
    assert setup.dest.read_bytes() == CONTENT
    assert _statuses(setup.server) == [("bytes=5000-", 206)]


def test_server_ignoring_range_restarts_from_zero(setup):
    setup.part.parent.mkdir(parents=True)
    setup.part.write_bytes(CONTENT[:5000])
    setup.server.set_fault(PATH, ignore_range=True)
    result = setup.run()
    assert result.status == DOWNLOADED
    assert setup.dest.read_bytes() == CONTENT
    assert _statuses(setup.server) == [("bytes=5000-", 200)]


def test_corrupt_part_file_is_discarded_and_redownloaded(setup):
    # A stale .part whose bytes don't match: the resumed file fails md5,
    # the .part is deleted, and the next attempt downloads from zero.
    setup.part.parent.mkdir(parents=True)
    setup.part.write_bytes(b"\xff" * 5000)
    result = setup.run()
    assert result.status == DOWNLOADED
    assert setup.dest.read_bytes() == CONTENT
    assert _statuses(setup.server) == [("bytes=5000-", 206), (None, 200)]


def test_500_twice_then_ok(setup):
    setup.server.set_fault(PATH, status=500, times=2)
    result = setup.run()
    assert result.status == DOWNLOADED
    assert result.attempts == 3
    assert setup.sleeps == [5, 10]


# ---- failure paths ----

def test_wrong_bytes_retried_then_fails(setup):
    setup.server.set_fault(PATH, wrong_bytes=True)
    result = setup.run(tries=3)
    assert result.status == FAILED
    assert result.attempts == 3
    assert "md5" in result.error
    assert len(setup.server.requests) == 3
    assert setup.sleeps == [5, 10]
    assert not setup.dest.exists()
    assert not setup.part.exists()  # a wrong file is never kept
    assert PATH not in setup.state.load_verified()


@pytest.mark.parametrize("code", [401, 403, 404])
def test_permanent_http_errors_are_not_retried(setup, code):
    setup.server.set_fault(PATH, status=code)
    result = setup.run()
    assert result.status == FAILED
    assert result.attempts == 1
    assert str(code) in result.error
    assert len(setup.server.requests) == 1
    assert setup.sleeps == []


def test_persistent_500_uses_full_backoff(setup):
    setup.server.set_fault(PATH, status=500)
    result = setup.run(tries=5)
    assert result.status == FAILED
    assert result.attempts == 5
    assert setup.sleeps == [5, 10, 20, 40]


def test_backoff_is_capped_at_60_seconds():
    assert [backoff_seconds(n) for n in range(1, 7)] == [5, 10, 20, 40, 60, 60]


# ---- existing files (e.g. a 1.2a input directory) ----

def test_verified_file_is_skipped_without_any_request(setup):
    setup.dest.parent.mkdir(parents=True)
    setup.dest.write_bytes(CONTENT)
    setup.state.record_verified(PATH, setup.entry.size, setup.entry.md5)
    result = setup.run()
    assert result.status == SKIPPED
    assert setup.server.requests == []


def test_existing_correct_file_not_in_state_is_hashed_and_recorded(setup):
    setup.dest.parent.mkdir(parents=True)
    setup.dest.write_bytes(CONTENT)
    result = setup.run()
    assert result.status == VERIFIED_EXISTING
    assert setup.server.requests == []
    assert PATH in setup.state.load_verified()


def test_existing_wrong_file_is_moved_aside_and_redownloaded(setup):
    setup.dest.parent.mkdir(parents=True)
    setup.dest.write_bytes(b"old wrong content")
    result = setup.run()
    assert result.status == DOWNLOADED
    assert setup.dest.read_bytes() == CONTENT
    assert setup.bad.read_bytes() == b"old wrong content"


def test_state_says_verified_but_file_changed_is_rechecked(setup):
    # The state record is only trusted if the file on disk still has the
    # recorded size; a truncated file is re-checked and re-downloaded.
    setup.dest.parent.mkdir(parents=True)
    setup.dest.write_bytes(CONTENT[:10])
    setup.state.record_verified(PATH, setup.entry.size, setup.entry.md5)
    result = setup.run()
    assert result.status == DOWNLOADED
    assert setup.dest.read_bytes() == CONTENT


def test_correct_symlinked_file_is_kept_as_a_link(setup, tmp_path):
    target = tmp_path / "elsewhere" / "XC.data"
    target.parent.mkdir()
    target.write_bytes(CONTENT)
    setup.dest.parent.mkdir(parents=True)
    setup.dest.symlink_to(target)
    result = setup.run()
    assert result.status == VERIFIED_EXISTING
    assert setup.dest.is_symlink()
    assert setup.server.requests == []


def test_wrong_symlinked_file_moves_the_link_not_its_target(setup, tmp_path):
    # A linked input tree points into a directory we must never change.
    target = tmp_path / "elsewhere" / "XC.data"
    target.parent.mkdir()
    target.write_bytes(b"wrong")
    setup.dest.parent.mkdir(parents=True)
    setup.dest.symlink_to(target)
    result = setup.run()
    assert result.status == DOWNLOADED
    assert target.read_bytes() == b"wrong"  # target untouched
    assert setup.bad.is_symlink() and os.readlink(setup.bad) == str(target)
    assert not setup.dest.is_symlink()
    assert setup.dest.read_bytes() == CONTENT


def test_md5_file_matches_hashlib(tmp_path):
    f = tmp_path / "x"
    f.write_bytes(CONTENT)
    assert md5_file(f) == hashlib.md5(CONTENT).hexdigest()
