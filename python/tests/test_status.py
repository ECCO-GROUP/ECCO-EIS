"""Tests for `emu inputs status` (emu.inputs.status and the CLI)."""

import hashlib
import json
import os
import socket
import threading
import time
import urllib.request

import pytest

from emu import cli
from emu.inputs.fetch import fetch
from emu.inputs.manifest import InventoryEntry
from emu.inputs.state import FetchState
from emu.inputs.status import collect_status, format_status

SIZES = [1000, 2000, 3000, 4000]


@pytest.fixture
def entries():
    return [InventoryEntry(f"d/f{i}.data", s, f"md5-{i}") for i, s in enumerate(SIZES)]


def _snapshot_files(root):
    # Every file under root with its size and mtime, to prove status writes nothing
    return {p: (p.stat().st_size, p.stat().st_mtime_ns) for p in root.rglob("*")}


def _write_snapshot(root, **fields):
    snap = {"state": "running", "pid": os.getpid(), "host": socket.gethostname(),
            "updated": "2026-11-18T00:00:00Z", "files_done": 2, "files_total": 4,
            "bytes_done": 3000, "bytes_total": 10000, "failed": 0, "retrying": 1,
            "rate_bytes_per_s": 2.5e6, "eta_seconds": 125.0, "elapsed_seconds": 60.0}
    snap.update(fields)
    (root / ".emu_fetch_progress.json").write_text(json.dumps(snap))


def test_empty_directory(entries, tmp_path):
    s = collect_status(entries, tmp_path)
    assert (s.files_done, s.files_total, s.bytes_done, s.bytes_total) == (0, 4, 0, 10000)
    assert s.running is None
    text = format_status(s)
    assert "0/4 files (0%) in place" in text
    assert "4 files (0.0 GB) still to fetch" in text
    assert "No fetch has run in this directory" in text


def test_partially_fetched_counts_verified_files(entries, tmp_path):
    state = FetchState(tmp_path / ".emu_fetch_state")
    state.record_verified(entries[1].path, entries[1].size, entries[1].md5)
    state.record_verified(entries[3].path, entries[3].size, entries[3].md5)
    s = collect_status(entries, tmp_path)
    assert (s.files_done, s.bytes_done) == (2, 6000)
    assert "2/4 files (50%) in place" in format_status(s)
    assert "2 files (0.0 GB) still to fetch" in format_status(s)


def test_record_for_a_different_md5_does_not_count(entries, tmp_path):
    # A verified record is only for the inventory's md5; an old record
    # from a different version of the file doesn't count as in place
    FetchState(tmp_path / ".emu_fetch_state").record_verified(entries[0].path, 1000, "old-md5")
    assert collect_status(entries, tmp_path).files_done == 0


def test_last_run_failures_are_shown(entries, tmp_path):
    (tmp_path / "fetch_failures.txt").write_text(
        "d/f2.data\t5 attempt(s)\tHTTP 404 Not Found for http://x/d/f2.data\n")
    text = format_status(collect_status(entries, tmp_path))
    assert "1 file failed in the last run" in text
    assert "d/f2.data" in text and "HTTP 404" in text


def test_running_fetch_shows_rate_and_eta(entries, tmp_path):
    (tmp_path / ".emu_fetch.lock").write_text(json.dumps({"pid": os.getpid(), "host": socket.gethostname()}))
    _write_snapshot(tmp_path)
    s = collect_status(entries, tmp_path)
    assert s.running == "running"
    text = format_status(s)
    assert "Fetch running (pid" in text
    assert "2 MB/s" in text and "ETA 0:03" in text and "1 retrying" in text


def test_running_snapshot_overrides_state_counts(entries, tmp_path):
    # While a fetch runs its live counts (incl. in-progress bytes) are newer
    # than the state file, so status shows them
    (tmp_path / ".emu_fetch.lock").write_text(json.dumps({"pid": os.getpid(), "host": socket.gethostname()}))
    _write_snapshot(tmp_path, files_done=3, bytes_done=7500)
    s = collect_status(entries, tmp_path)
    assert (s.files_done, s.bytes_done) == (3, 7500)


def test_stale_lock_shows_last_run_interrupted(entries, tmp_path):
    dead = _dead_pid()
    (tmp_path / ".emu_fetch.lock").write_text(json.dumps({"pid": dead, "host": socket.gethostname()}))
    _write_snapshot(tmp_path, pid=dead)
    s = collect_status(entries, tmp_path)
    assert s.running is None
    assert "Not running (last run interrupted" in format_status(s)


def test_lock_from_another_host_is_reported_as_unknown(entries, tmp_path):
    (tmp_path / ".emu_fetch.lock").write_text(json.dumps({"pid": 1, "host": "other.example"}))
    text = format_status(collect_status(entries, tmp_path))
    assert "other.example" in text and "can't tell" in text


def test_finished_run_reported(entries, tmp_path):
    _write_snapshot(tmp_path, state="finished", updated="2026-11-18T03:04:05Z")
    text = format_status(collect_status(entries, tmp_path))
    assert "Last fetch finished at 2026-11-18T03:04:05Z" in text


def test_status_never_writes_anything(entries, tmp_path):
    state = FetchState(tmp_path / ".emu_fetch_state")
    state.record_verified(entries[0].path, entries[0].size, entries[0].md5)
    (tmp_path / ".emu_fetch.lock").write_text(json.dumps({"pid": _dead_pid(), "host": socket.gethostname()}))
    _write_snapshot(tmp_path)
    (tmp_path / "fetch_failures.txt").write_text("d/f2.data\t1 attempt(s)\tx\n")
    before = _snapshot_files(tmp_path)
    format_status(collect_status(entries, tmp_path))
    assert _snapshot_files(tmp_path) == before


def test_status_while_a_fetch_runs(drive_server, tmp_path):
    # Run a real fetch in a thread and call status alongside it
    entries = []
    for i in range(8):
        data = os.urandom(5000)
        drive_server.add_file(f"d/f{i}.data", data)
        entries.append(InventoryEntry(f"d/f{i}.data", len(data), hashlib.md5(data).hexdigest()))
    drive_server.delay = 0.2
    root = tmp_path / "in"
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    errors = []

    def run():
        # Keep any exception from the fetch thread so the test can report it
        try:
            fetch(entries, drive_server.url, root, (drive_server.username, drive_server.password),
                  jobs=1, opener=opener, tick_seconds=0.05, live=False)
        except Exception as e:  # pragma: no cover - only on failure
            errors.append(e)

    thread = threading.Thread(target=run)
    thread.start()
    seen_running = []
    deadline = time.monotonic() + 30
    while thread.is_alive() and time.monotonic() < deadline:
        if (root / ".emu_fetch_progress.json").exists():
            s = collect_status(entries, root)
            seen_running.append(s.running)
        time.sleep(0.05)
    thread.join(timeout=10)
    assert not thread.is_alive(), "fetch thread did not finish"
    assert errors == []
    assert "running" in seen_running
    final = collect_status(entries, root)
    assert final.running is None and final.files_done == 8
    assert "Last fetch finished" in format_status(final)


# ---- CLI ----

def test_cli_status(entries, tmp_path, monkeypatch, capsys):
    from emu.releases import Release

    inventory = tmp_path / "inv.txt"
    inventory.write_text("".join(f"F|{e.size}|{e.md5}|./{e.path}\n" for e in entries))
    release = Release("test-release", "http://unused.example", {"d": "d"}, [], {"samp": ["d"]},
                      str(inventory))
    monkeypatch.setattr(cli, "load_release", lambda name: release)
    root = tmp_path / "in"
    root.mkdir()
    FetchState(root / ".emu_fetch_state").record_verified(entries[0].path, entries[0].size, entries[0].md5)

    assert cli.main(["inputs", "status", "--dir", str(root)]) == 0
    out = capsys.readouterr().out
    assert "1/4 files (25%) in place" in out
    assert "all files of release test-release" in out

    assert cli.main(["inputs", "status", "--dir", str(root), "--tools", "samp"]) == 0
    assert "tools samp" in capsys.readouterr().out


def test_cli_status_missing_directory(tmp_path, capsys):
    assert cli.main(["inputs", "status", "--dir", str(tmp_path / "nope")]) == 2
    assert "does not exist" in capsys.readouterr().err


def _dead_pid():
    for candidate in range(2**22, 2, -1):
        try:
            os.kill(candidate, 0)
        except ProcessLookupError:
            return candidate
        except PermissionError:
            continue
    pytest.fail("no unused PID")


# ---- wording by mode (fetch vs verify) ----

def test_running_verify_is_named_and_shows_still_to_check(entries, tmp_path):
    (tmp_path / ".emu_fetch.lock").write_text(json.dumps({"pid": os.getpid(), "host": socket.gethostname()}))
    _write_snapshot(tmp_path, mode="verify", retrying=0)
    text = format_status(collect_status(entries, tmp_path))
    assert "Verify running (pid" in text
    assert "2 MB/s" in text and "ETA 0:03" in text
    assert "still to check" in text and "still to fetch" not in text


def test_finished_verify_is_reported_as_a_verify(entries, tmp_path):
    _write_snapshot(tmp_path, mode="verify", state="finished", updated="2026-11-19T22:18:52Z")
    text = format_status(collect_status(entries, tmp_path))
    assert "Last verify finished at 2026-11-19T22:18:52Z" in text
    assert "No fetch has run" not in text


def test_verify_only_history_without_snapshot_is_not_called_no_fetch(entries, tmp_path):
    # A directory verified by an older emu (state file, no snapshot) has
    # still been worked on; status mustn't claim nothing has run
    FetchState(tmp_path / ".emu_fetch_state").record_verified(entries[0].path, entries[0].size, entries[0].md5)
    text = format_status(collect_status(entries, tmp_path))
    assert "No fetch has run" not in text
    assert "No fetch or verify run recorded" not in text


def test_snapshot_without_mode_is_treated_as_fetch(entries, tmp_path):
    _write_snapshot(tmp_path, state="finished", updated="2026-11-18T03:04:05Z")
    assert "Last fetch finished" in format_status(collect_status(entries, tmp_path))


def test_status_while_a_verify_runs(tmp_path):
    from emu.inputs.fetch import verify

    root = tmp_path / "in"
    ents = []
    for i in range(30):
        data = os.urandom(200_000)
        (root / "d").mkdir(parents=True, exist_ok=True)
        (root / "d" / f"f{i}").write_bytes(data)
        ents.append(InventoryEntry(f"d/f{i}", len(data), hashlib.md5(data).hexdigest()))

    import emu.inputs.fetch as fetchmod
    real_check = fetchmod.check_file

    def slow_check(entry, r):
        time.sleep(0.03)  # slow enough for status to see the run
        return real_check(entry, r)

    fetchmod.check_file = slow_check
    try:
        t = threading.Thread(target=verify, args=(ents, root), kwargs={"jobs": 1, "tick_seconds": 0.02})
        t.start()
        seen = []
        while t.is_alive():
            if (root / ".emu_fetch_progress.json").exists():
                seen.append(format_status(collect_status(ents, root)))
            time.sleep(0.02)
        t.join()
    finally:
        fetchmod.check_file = real_check
    assert any("Verify running" in s and "MB/s" in s for s in seen)
    assert "Last verify finished" in format_status(collect_status(ents, root))


# ---- verify failures and leftover .part files ----

def test_last_verify_failures_are_shown(entries, tmp_path):
    (tmp_path / "verify_failures.txt").write_text(
        "missing\td/f0.data\nwrong md5\td/f3.data\n")
    _write_snapshot(tmp_path, mode="verify", state="finished")
    text = format_status(collect_status(entries, tmp_path))
    assert "2 problems found by the last verify" in text
    assert "missing: d/f0.data" in text and "wrong md5: d/f3.data" in text


def test_leftover_part_files_are_reported(entries, tmp_path):
    (tmp_path / "d").mkdir()
    (tmp_path / "d" / "f1.data.part").write_bytes(b"x" * 1500)
    (tmp_path / "d" / "f2.data.part").write_bytes(b"x" * 500)
    s = collect_status(entries, tmp_path)
    assert s.parts == [("d/f1.data", 1500), ("d/f2.data", 500)]
    text = format_status(s)
    assert "2 partly downloaded files (.part, 0.0 GB)" in text
    assert "rerun the fetch" in text


def test_part_for_a_file_outside_the_selection_is_named_as_such(entries, tmp_path):
    # A .part from another selection (e.g. trc, when samp is shown) isn't
    # finished by rerunning this selection's fetch; say so
    other = tmp_path / "forcing" / "x.data.part"
    other.parent.mkdir(parents=True)
    other.write_bytes(b"y" * 10)
    text = format_status(collect_status(entries, tmp_path))
    assert "1 .part file is for a file outside this selection" in text


def test_part_files_while_running_are_not_called_leftovers(entries, tmp_path):
    (tmp_path / ".emu_fetch.lock").write_text(json.dumps({"pid": os.getpid(), "host": socket.gethostname()}))
    _write_snapshot(tmp_path)
    (tmp_path / "d").mkdir()
    (tmp_path / "d" / "f1.data.part").write_bytes(b"x" * 10)
    text = format_status(collect_status(entries, tmp_path))
    assert "partly downloaded" not in text  # in progress, not left over


def test_no_part_files_no_mention(entries, tmp_path):
    assert ".part" not in format_status(collect_status(entries, tmp_path))


def test_part_scan_does_not_follow_or_count_symlinks(entries, tmp_path):
    # Linked input trees are full of symlinks; the scan must not follow
    # them (slow over NFS), and a symlink isn't a leftover download
    outside = tmp_path / "outside"
    outside.mkdir()
    (outside / "f1.data.part").write_bytes(b"x")
    root = tmp_path / "in"
    (root / "d").mkdir(parents=True)
    os.symlink(outside, root / "linked_dir")                 # not followed
    os.symlink(outside / "f1.data.part", root / "d" / "f1.data.part")  # not counted
    s = collect_status(entries, root)
    assert s.parts == [] and s.other_parts == 0
