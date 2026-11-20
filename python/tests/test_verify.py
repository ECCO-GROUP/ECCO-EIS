"""Tests for verify-only mode (emu.inputs.fetch.verify and
`emu inputs fetch --verify-only`): re-check md5s on disk, no network.
"""

import hashlib
import os

import pytest

from emu import cli
from emu.inputs.fetch import EXIT_FAILURES, EXIT_OK, verify
from emu.inputs.manifest import InventoryEntry
from emu.inputs.state import FetchState
from emu.releases import Release


def _make(root, files):
    """Write files under root; return InventoryEntry list for them."""
    entries = []
    for path, content in files.items():
        (root / path).parent.mkdir(parents=True, exist_ok=True)
        (root / path).write_bytes(content)
        entries.append(InventoryEntry(path, len(content), hashlib.md5(content).hexdigest()))
    return entries


@pytest.fixture
def good(tmp_path):
    root = tmp_path / "in"
    entries = _make(root, {f"d/f{i}.data": os.urandom(1000 + i) for i in range(5)})
    return root, entries


def test_all_correct_exits_0_and_records_state(good):
    root, entries = good
    summary = verify(entries, root)
    assert summary.exit_code == EXIT_OK
    assert summary.ok == 5
    assert (summary.missing, summary.wrong_size, summary.wrong_md5) == ([], [], [])
    verified = FetchState(root / ".emu_fetch_state").load_verified()
    assert set(verified) == {e.path for e in entries}


def test_problems_reported_by_category(good):
    root, entries = good
    os.remove(root / entries[0].path)                      # missing
    (root / entries[1].path).write_bytes(b"short")          # wrong size
    data = bytearray((root / entries[2].path).read_bytes())
    data[0] ^= 0xFF
    (root / entries[2].path).write_bytes(bytes(data))       # same size, wrong md5

    summary = verify(entries, root)
    assert summary.exit_code == EXIT_FAILURES
    assert [e.path for e in summary.missing] == [entries[0].path]
    assert [e.path for e in summary.wrong_size] == [entries[1].path]
    assert [e.path for e in summary.wrong_md5] == [entries[2].path]
    assert summary.ok == 2

    report = (root / "verify_failures.txt").read_text()
    assert f"missing\t{entries[0].path}" in report
    assert f"wrong size\t{entries[1].path}" in report
    assert f"wrong md5\t{entries[2].path}" in report


def test_ignores_existing_state_and_rehashes(good):
    # A file recorded as verified but since corrupted must be caught: the
    # state file is not trusted in verify mode
    root, entries = good
    state = FetchState(root / ".emu_fetch_state")
    for e in entries:
        state.record_verified(e.path, e.size, e.md5)
    data = bytearray((root / entries[3].path).read_bytes())
    data[-1] ^= 0xFF
    (root / entries[3].path).write_bytes(bytes(data))

    summary = verify(entries, root)
    assert [e.path for e in summary.wrong_md5] == [entries[3].path]


def test_bad_files_are_removed_from_the_state_record(good):
    # After verify, status must not count a file that failed the check
    root, entries = good
    state = FetchState(root / ".emu_fetch_state")
    for e in entries:
        state.record_verified(e.path, e.size, e.md5)
    os.remove(root / entries[4].path)
    verify(entries, root)
    assert entries[4].path not in FetchState(root / ".emu_fetch_state").load_verified()


def test_symlinked_files_are_verified_through_the_link_and_not_changed(tmp_path):
    target_dir = tmp_path / "elsewhere"
    target_entries = _make(target_dir, {"a.data": b"a" * 500})
    root = tmp_path / "in"
    (root / "d").mkdir(parents=True)
    os.symlink(target_dir / "a.data", root / "d" / "a.data")
    entry = InventoryEntry("d/a.data", 500, target_entries[0].md5)
    before = (target_dir / "a.data").stat().st_mtime_ns

    assert verify([entry], root).exit_code == EXIT_OK
    assert (root / "d" / "a.data").is_symlink()
    assert (target_dir / "a.data").stat().st_mtime_ns == before
    assert not any(target_dir.glob(".emu*"))  # nothing written next to the target


def test_clean_verify_removes_an_old_failure_report(good):
    root, entries = good
    (root / "verify_failures.txt").write_text("old\n")
    verify(entries, root)
    assert not (root / "verify_failures.txt").exists()


def test_verify_takes_the_lock(good):
    import json
    import socket

    from emu.inputs.state import LockHeldError

    root, entries = good
    (root / ".emu_fetch.lock").write_text(json.dumps({"pid": os.getpid(), "host": socket.gethostname()}))
    with pytest.raises(LockHeldError):
        verify(entries, root)


def test_verify_runs_in_parallel_and_reports_progress(good):
    root, entries = good
    seen = []
    summary = verify(entries, root, jobs=3, on_result=lambda path, status: seen.append(status))
    assert summary.ok == 5 and len(seen) == 5


# ---- CLI ----

@pytest.fixture
def cli_release(good, tmp_path, monkeypatch, drive_server):
    root, entries = good
    inventory = tmp_path / "inv.txt"
    inventory.write_text("".join(f"F|{e.size}|{e.md5}|./{e.path}\n" for e in entries))
    release = Release("test-release", drive_server.base_url, {"d": "d"}, ["d"], {"samp": []},
                      str(inventory))
    monkeypatch.setattr(cli, "load_release", lambda name: release)
    monkeypatch.setattr(cli, "_interactive", lambda: False)
    return root, entries, drive_server


def test_cli_verify_only_makes_no_network_requests(cli_release, capsys, monkeypatch):
    root, entries, server = cli_release
    # Even a credential prompt would be wrong: verify needs no credentials
    monkeypatch.setattr("builtins.input", lambda p="": pytest.fail("verify-only must not prompt"))
    code = cli.main(["inputs", "fetch", "--verify-only", "--dir", str(root), "--all"])
    assert code == 0
    assert server.requests == []
    assert "5 correct" in capsys.readouterr().out


def test_cli_verify_only_reports_problems_and_exits_1(cli_release, capsys):
    root, entries, server = cli_release
    os.remove(root / entries[0].path)
    code = cli.main(["inputs", "fetch", "--verify-only", "--dir", str(root), "--all"])
    assert code == 1
    out = capsys.readouterr().out
    assert "1 missing" in out and entries[0].path in out
    assert server.requests == []


def test_cli_verify_only_missing_directory_exits_2(cli_release, tmp_path, capsys):
    code = cli.main(["inputs", "fetch", "--verify-only", "--dir", str(tmp_path / "nope"), "--all"])
    assert code == 2
    assert not (tmp_path / "nope").exists()  # verify never creates the directory


def test_guided_verify_shows_command_with_verify_only(cli_release, capsys, monkeypatch):
    root, entries, server = cli_release
    monkeypatch.setattr(cli, "_interactive", lambda: True)
    answers = iter(["1", "y"])  # tool menu choice, then confirm
    monkeypatch.setattr("builtins.input", lambda p="": next(answers))
    code = cli.main(["inputs", "fetch", "--verify-only", "--dir", str(root)])
    assert code == 0
    out = capsys.readouterr().out
    assert f"emu inputs fetch --dir {root} --tools samp --verify-only" in out
    assert server.requests == []


# ---- progress reporting during verify (rate/ETA, log, snapshot) ----

def test_verify_writes_snapshot_and_progress_log(good):
    import json

    root, entries = good
    verify(entries, root, tick_seconds=0.01, log_interval=0)
    snap = json.loads((root / ".emu_fetch_progress.json").read_text())
    assert snap["mode"] == "verify"
    assert snap["state"] == "finished"
    assert snap["files_done"] == 5 and snap["files_total"] == 5
    assert snap["bytes_done"] == sum(e.size for e in entries)
    log = (root / "fetch_progress.log").read_text().splitlines()
    assert any("verify started" in l for l in log)
    assert log[-1].split(" ", 2)[2] == "verify finished: 5 correct, 0 missing, 0 wrong size, 0 wrong md5"


def test_verify_counts_checked_bytes_for_the_rate(good, monkeypatch):
    # The rate during a verify is bytes read for md5s, so each checked
    # file adds its size to bytes_transferred, problems included
    import emu.inputs.fetch as fetchmod

    root, entries = good
    os.remove(root / entries[0].path)
    seen = {}
    real = fetchmod.Progress

    class Spy(real):
        def __init__(self, *a, **k):
            super().__init__(*a, **k)
            seen["p"] = self

    monkeypatch.setattr(fetchmod, "Progress", Spy)
    verify(entries, root, tick_seconds=0.01)
    p = seen["p"]
    assert p.bytes_transferred == sum(e.size for e in entries[1:])
    assert p.files_done == 4 and p.failed == 1
