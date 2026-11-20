"""Tests for the trc post-processing step (emu.inputs.fetch.postprocess
and its use by `emu inputs fetch`): after the tracer inputs are in
place, build state_weekly_rev_time_227808 by running the release's
reverseintime_all.sh, as 1.2a's emu_input_install.sh does.

The tests use a stand-in script, never the real one.
"""

import hashlib
import os
import urllib.request

import pytest

from emu import cli
from emu.inputs.fetch import (POSTPROCESS_FAILED, POSTPROCESS_DONE, POSTPROCESS_NOT_NEEDED,
                              POSTPROCESS_EXISTS, POSTPROCESS_INCOMPLETE, fetch, postprocess)
from emu.inputs.manifest import InventoryEntry
from emu.inputs.state import FetchState
from emu.releases import Release, load_release

WORKDIR = "forcing/other/flux-forced"
CREATES = "forcing/other/flux-forced/state_weekly_rev_time_227808"

GOOD_SCRIPT = b"""#!/bin/bash
# Stand-in for reverseintime_all.sh: record where it ran and what it saw
mkdir -p state_weekly_rev_time_227808/Convtave
pwd > state_weekly_rev_time_227808/ran_in.txt
ls state_weekly > state_weekly_rev_time_227808/saw.txt
echo "built"
"""

FAILING_SCRIPT = b"""#!/bin/bash
mkdir -p state_weekly_rev_time_227808/Convtave
echo "missing input file" 1>&2
exit 1
"""


def _rule():
    return {
        "tool": "trc",
        "requires": ["forcing/other/flux-forced/state_weekly", "scripts"],
        "scripts_dir": "scripts",
        "workdir": WORKDIR,
        "script": "reverseintime_all.sh",
        "creates": CREATES,
    }


def _release(inventory="unused"):
    return Release("test", "http://unused.example", {}, [], {"trc": [], "samp": []},
                   inventory, postprocess=_rule())


def _entries_on_disk(root, script=GOOD_SCRIPT, verified=True):
    """Lay out a small trc input tree; return its entries."""
    files = {
        f"{WORKDIR}/state_weekly/Convtave/Convtave.0000000168.data": b"c" * 100,
        "scripts/reverseintime_all.sh": script,
        "scripts/reverseintime.sh": b"#!/bin/bash\n",
    }
    entries = []
    for path, content in files.items():
        (root / path).parent.mkdir(parents=True, exist_ok=True)
        (root / path).write_bytes(content)
        entries.append(InventoryEntry(path, len(content), hashlib.md5(content).hexdigest()))
    if verified:
        state = FetchState(root / ".emu_fetch_state")
        for e in entries:
            state.record_verified(e.path, e.size, e.md5)
    return entries


def test_runs_script_in_workdir_with_scripts_linked(tmp_path):
    entries = _entries_on_disk(tmp_path)
    result = postprocess(_release(), entries, tmp_path, tools=["trc"])
    assert result.status == POSTPROCESS_DONE
    created = tmp_path / CREATES
    assert (created / "ran_in.txt").read_text().strip() == str(tmp_path / WORKDIR)
    assert (created / "saw.txt").read_text().split() == ["Convtave"]
    # scripts/* are symlinked into the workdir, as 1.2a does
    link = tmp_path / WORKDIR / "reverseintime_all.sh"
    assert link.is_symlink() and os.readlink(link) == str(tmp_path / "scripts/reverseintime_all.sh")
    assert "built" in (tmp_path / "postprocess.log").read_text()


def test_works_with_a_relative_root(tmp_path, monkeypatch):
    # The links into the work directory must point at the scripts by an
    # absolute path, or they dangle once the script runs in the workdir
    entries = _entries_on_disk(tmp_path / "in")
    monkeypatch.chdir(tmp_path)
    result = postprocess(_release(), entries, "in", tools=["trc"])
    assert result.status == POSTPROCESS_DONE, result.message
    link = tmp_path / "in" / WORKDIR / "reverseintime_all.sh"
    assert os.path.isabs(os.readlink(link)) and link.exists()


def test_not_run_when_the_directory_already_exists(tmp_path):
    entries = _entries_on_disk(tmp_path)
    (tmp_path / CREATES).mkdir(parents=True)
    result = postprocess(_release(), entries, tmp_path, tools=["trc"])
    assert result.status == POSTPROCESS_EXISTS
    assert not (tmp_path / CREATES / "ran_in.txt").exists()


def test_not_run_when_trc_inputs_are_incomplete(tmp_path):
    entries = _entries_on_disk(tmp_path, verified=False)
    state = FetchState(tmp_path / ".emu_fetch_state")
    for e in entries[1:]:  # state_weekly file not verified
        state.record_verified(e.path, e.size, e.md5)
    result = postprocess(_release(), entries, tmp_path, tools=["trc"])
    assert result.status == POSTPROCESS_INCOMPLETE
    assert not (tmp_path / CREATES).exists()


def test_not_run_when_trc_is_not_selected(tmp_path):
    entries = _entries_on_disk(tmp_path)
    assert postprocess(_release(), entries, tmp_path, tools=["samp"]).status == POSTPROCESS_NOT_NEEDED
    assert not (tmp_path / CREATES).exists()


def test_run_for_all_tools(tmp_path):
    entries = _entries_on_disk(tmp_path)
    assert postprocess(_release(), entries, tmp_path, select_all=True).status == POSTPROCESS_DONE


def test_release_without_a_rule_needs_nothing(tmp_path):
    entries = _entries_on_disk(tmp_path)
    release = Release("test", "http://x", {}, [], {"trc": []}, "unused")
    assert postprocess(release, entries, tmp_path, tools=["trc"]).status == POSTPROCESS_NOT_NEEDED


def test_script_failure_is_reported_and_partial_directory_moved_aside(tmp_path):
    entries = _entries_on_disk(tmp_path, script=FAILING_SCRIPT)
    result = postprocess(_release(), entries, tmp_path, tools=["trc"])
    assert result.status == POSTPROCESS_FAILED
    assert "missing input file" in result.message
    # The half-built directory is moved aside (not deleted), so a rerun
    # tries again instead of skipping because the directory exists
    assert not (tmp_path / CREATES).exists()
    assert (tmp_path / (CREATES + ".incomplete") / "Convtave").is_dir()


def test_rerun_after_failure_tries_again(tmp_path):
    entries = _entries_on_disk(tmp_path, script=FAILING_SCRIPT)
    postprocess(_release(), entries, tmp_path, tools=["trc"])
    (tmp_path / "scripts/reverseintime_all.sh").write_bytes(GOOD_SCRIPT)
    result = postprocess(_release(), entries, tmp_path, tools=["trc"])
    assert result.status == POSTPROCESS_DONE
    assert (tmp_path / CREATES / "ran_in.txt").exists()


def test_missing_script_is_reported(tmp_path):
    entries = _entries_on_disk(tmp_path)
    os.remove(tmp_path / "scripts/reverseintime_all.sh")
    entries = [e for e in entries if not e.path.endswith("reverseintime_all.sh")]
    result = postprocess(_release(), entries, tmp_path, tools=["trc"])
    assert result.status == POSTPROCESS_FAILED
    assert "reverseintime_all.sh" in result.message


def test_v4r4_release_has_the_rule():
    rule = load_release("v4r4-llc90-flux").postprocess
    assert rule["tool"] == "trc"
    assert rule["creates"] == CREATES
    assert rule["workdir"] == WORKDIR
    assert rule["script"] == "reverseintime_all.sh"
    assert set(rule["requires"]) == {"forcing/other/flux-forced/state_weekly", "scripts"}


# ---- through fetch() and the CLI ----

def test_correct_symlinked_input_is_kept_recorded_and_not_downloaded(drive_server, tmp_path):
    target = tmp_path / "elsewhere" / "a.data"
    target.parent.mkdir()
    target.write_bytes(b"a" * 300)
    root = tmp_path / "in"
    (root / "d").mkdir(parents=True)
    os.symlink(target, root / "d" / "a.data")
    entry = InventoryEntry("d/a.data", 300, hashlib.md5(b"a" * 300).hexdigest())
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    summary = fetch([entry], drive_server.url, root, (drive_server.username, drive_server.password),
                    opener=opener, live=False)
    assert summary.exit_code == 0
    assert (root / "d" / "a.data").is_symlink()
    assert "d/a.data" in FetchState(root / ".emu_fetch_state").load_verified()
    assert drive_server.requests == []


@pytest.fixture
def trc_remote(drive_server, tmp_path, monkeypatch):
    """Serve a small trc tree from the fake server, with the stand-in script."""
    files = {
        f"{WORKDIR}/state_weekly/Convtave/Convtave.0000000168.data": b"c" * 100,
        "scripts/reverseintime_all.sh": GOOD_SCRIPT,
    }
    lines = []
    for path, content in files.items():
        drive_server.add_file("remote/" + path, content)
        lines.append(f"F|{len(content)}|{hashlib.md5(content).hexdigest()}|./{path}")
    inventory = tmp_path / "inv.txt"
    inventory.write_text("\n".join(lines) + "\n")
    release = Release("test", drive_server.base_url,
                      {f"{WORKDIR}/state_weekly": f"remote/{WORKDIR}/state_weekly", "scripts": "remote/scripts"},
                      [], {"trc": [f"{WORKDIR}/state_weekly", "scripts"], "samp": []},
                      str(inventory), postprocess=_rule())
    monkeypatch.setattr(cli, "load_release", lambda name: release)
    monkeypatch.setattr(cli, "_interactive", lambda: False)
    for var in ["http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY"]:
        monkeypatch.delenv(var, raising=False)
    return drive_server


def _cmd(server, root, *extra):
    return ["inputs", "fetch", "--dir", str(root), "--tools", "trc",
            "--user", server.username, "--password", server.password, *extra]


def test_cli_fetch_trc_runs_postprocess(trc_remote, tmp_path, capsys):
    root = tmp_path / "in"
    assert cli.main(_cmd(trc_remote, root)) == 0
    assert (root / CREATES / "ran_in.txt").exists()
    assert "state_weekly_rev_time_227808" in capsys.readouterr().out


def test_cli_no_postprocess_skips_it(trc_remote, tmp_path, capsys):
    root = tmp_path / "in"
    assert cli.main(_cmd(trc_remote, root, "--no-postprocess")) == 0
    assert not (root / CREATES).exists()
    assert "--no-postprocess" in capsys.readouterr().out


def test_cli_postprocess_failure_exits_1(trc_remote, tmp_path, capsys):
    trc_remote.add_file("remote/scripts/reverseintime_all.sh", FAILING_SCRIPT)
    # Update the inventory's md5 for the failing script so the fetch succeeds
    inv = tmp_path / "inv.txt"
    lines = inv.read_text().splitlines()
    lines[1] = f"F|{len(FAILING_SCRIPT)}|{hashlib.md5(FAILING_SCRIPT).hexdigest()}|./scripts/reverseintime_all.sh"
    inv.write_text("\n".join(lines) + "\n")
    root = tmp_path / "in"
    assert cli.main(_cmd(trc_remote, root)) == 1
    out = capsys.readouterr().out
    assert "missing input file" in out and "postprocess.log" in out


def test_cli_incomplete_fetch_does_not_postprocess(trc_remote, tmp_path, capsys):
    trc_remote.set_fault(f"remote/{WORKDIR}/state_weekly/Convtave/Convtave.0000000168.data", status=404)
    root = tmp_path / "in"
    assert cli.main(_cmd(trc_remote, root, "--tries", "1")) == 1
    assert not (root / CREATES).exists()
