"""Tests for the `emu inputs fetch` command line (emu.cli).

The end-to-end tests point a temporary release at the fake ECCO Drive
server (drive_server), so nothing here contacts the real server.
"""

import hashlib
import json
import os
import socket

import pytest

from emu import cli
from emu.releases import Release

FILES = {
    "emu_ref/XC.data": b"x" * 3000,
    "emu_ref/YC.data": b"y" * 2000,
    "forcing/input_init/tile1.mitgrid": b"t" * 1000,
}


@pytest.fixture
def remote(drive_server, tmp_path, monkeypatch):
    """A fake release whose files are served by drive_server, plus an
    inventory listing them; the CLI is pointed at both.
    """
    inventory = tmp_path / "inventory.txt"
    lines = ["D|||."]
    for path, content in FILES.items():
        drive_server.add_file("remote/" + path, content)
        lines.append(f"F|{len(content)}|{hashlib.md5(content).hexdigest()}|./{path}")
    inventory.write_text("\n".join(lines) + "\n")

    release = Release(
        name="test-release",
        base_url=drive_server.base_url,
        path_map={"emu_ref": "remote/emu_ref", "forcing/input_init": "remote/forcing/input_init"},
        always_group=["forcing/input_init"],
        tool_groups={"samp": ["emu_ref"], "msim": []},
        inventory_path=str(inventory),
    )
    monkeypatch.setattr(cli, "load_release", lambda name: release)
    # Local requests must never go through a proxy
    for var in ["http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY", "all_proxy", "ALL_PROXY"]:
        monkeypatch.delenv(var, raising=False)
    monkeypatch.delenv("EMU_EARTHDATA_USER", raising=False)
    monkeypatch.delenv("EMU_WEBDAV_PASSWORD", raising=False)
    return drive_server


def _creds(server):
    return ["--user", server.username, "--password", server.password]


# ---- argument parsing ----

def test_tools_or_all_is_required(capsys):
    with pytest.raises(SystemExit) as exc_info:
        cli.main(["inputs", "fetch", "--dir", "x"])
    assert exc_info.value.code == 2
    assert "--tools" in capsys.readouterr().err


def test_tools_and_all_are_mutually_exclusive(capsys):
    with pytest.raises(SystemExit) as exc_info:
        cli.main(["inputs", "fetch", "--dir", "x", "--tools", "samp", "--all"])
    assert exc_info.value.code == 2


def test_dir_is_required(capsys):
    with pytest.raises(SystemExit) as exc_info:
        cli.main(["inputs", "fetch", "--all"])
    assert exc_info.value.code == 2
    assert "--dir" in capsys.readouterr().err


def test_defaults_and_options_are_parsed():
    args = cli.build_parser().parse_args(["inputs", "fetch", "--dir", "d", "--tools", "samp,trc"])
    assert args.release == "v4r4-llc90-flux"
    assert args.tools == ["samp", "trc"]
    assert (args.jobs, args.tries, args.log_interval, args.no_postprocess) == (8, 5, 60, False)

    args = cli.build_parser().parse_args([
        "inputs", "fetch", "--dir", "d", "--all", "--jobs", "3", "--tries", "2",
        "--log-interval", "10", "--no-postprocess", "--release", "other",
    ])
    assert args.all and args.release == "other"
    assert (args.jobs, args.tries, args.log_interval, args.no_postprocess) == (3, 2, 10, True)


@pytest.mark.parametrize("bad", [["--jobs", "0"], ["--tries", "0"], ["--log-interval", "-1"]])
def test_out_of_range_numbers_are_rejected(bad):
    with pytest.raises(SystemExit) as exc_info:
        cli.main(["inputs", "fetch", "--dir", "d", "--all"] + bad)
    assert exc_info.value.code == 2


def test_unknown_tool_exits_2_listing_valid_tools(remote, tmp_path, capsys):
    code = cli.main(["inputs", "fetch", "--dir", str(tmp_path / "in"), "--tools", "nope"]
                    + _creds(remote))
    assert code == 2
    err = capsys.readouterr().err
    assert "nope" in err and "samp" in err
    assert remote.requests == []


def test_unknown_release_exits_2(tmp_path, capsys):
    code = cli.main(["inputs", "fetch", "--dir", str(tmp_path), "--all",
                     "--release", "v9r9-none", "--user", "u", "--password", "p"])
    assert code == 2
    assert "v4r4-llc90-flux" in capsys.readouterr().err


# ---- credentials ----

def test_credentials_from_options_win_over_env(monkeypatch):
    monkeypatch.setenv("EMU_EARTHDATA_USER", "envuser")
    monkeypatch.setenv("EMU_WEBDAV_PASSWORD", "envpass")
    args = cli.build_parser().parse_args(
        ["inputs", "fetch", "--dir", "d", "--all", "--user", "optuser", "--password", "optpass"])
    assert cli.get_credentials(args) == ("optuser", "optpass")


def test_credentials_from_env_when_no_options(monkeypatch):
    monkeypatch.setenv("EMU_EARTHDATA_USER", "envuser")
    monkeypatch.setenv("EMU_WEBDAV_PASSWORD", "envpass")
    args = cli.build_parser().parse_args(["inputs", "fetch", "--dir", "d", "--all"])
    assert cli.get_credentials(args) == ("envuser", "envpass")


def test_credentials_prompted_when_missing(monkeypatch):
    monkeypatch.delenv("EMU_EARTHDATA_USER", raising=False)
    monkeypatch.delenv("EMU_WEBDAV_PASSWORD", raising=False)
    prompts = []
    monkeypatch.setattr("builtins.input", lambda prompt: prompts.append(prompt) or "promptuser")
    monkeypatch.setattr(cli.getpass, "getpass", lambda prompt: prompts.append(prompt) or "promptpass")
    args = cli.build_parser().parse_args(["inputs", "fetch", "--dir", "d", "--all"])
    assert cli.get_credentials(args) == ("promptuser", "promptpass")
    assert "Earthdata" in prompts[0] and "WebDAV" in prompts[1]


def test_only_missing_parts_are_prompted(monkeypatch):
    monkeypatch.setenv("EMU_EARTHDATA_USER", "envuser")
    monkeypatch.delenv("EMU_WEBDAV_PASSWORD", raising=False)
    monkeypatch.setattr("builtins.input", lambda prompt: pytest.fail("username was already set"))
    monkeypatch.setattr(cli.getpass, "getpass", lambda prompt: "promptpass")
    args = cli.build_parser().parse_args(["inputs", "fetch", "--dir", "d", "--all"])
    assert cli.get_credentials(args) == ("envuser", "promptpass")


def test_bad_credentials_exit_2_naming_earthdata_and_webdav(remote, tmp_path, capsys):
    code = cli.main(["inputs", "fetch", "--dir", str(tmp_path / "in"), "--all",
                     "--user", remote.username, "--password", "wrong"])
    assert code == 2
    err = capsys.readouterr().err
    assert "Earthdata" in err and "WebDAV" in err
    assert len(remote.requests) == 1  # checked once, nothing downloaded


def test_unreachable_server_exits_2(remote, tmp_path, capsys, monkeypatch):
    remote_release = cli.load_release("test-release")
    remote_release.base_url = "http://127.0.0.1:1"  # nothing listens on port 1
    code = cli.main(["inputs", "fetch", "--dir", str(tmp_path / "in"), "--all"] + _creds(remote))
    assert code == 2
    assert "cannot reach" in capsys.readouterr().err.lower()


# ---- end to end ----

def test_end_to_end_fetch_exits_0(remote, tmp_path, capsys):
    root = tmp_path / "new" / "inputs"  # created if missing
    code = cli.main(["inputs", "fetch", "--dir", str(root), "--all"] + _creds(remote))
    assert code == 0
    for path, content in FILES.items():
        assert (root / path).read_bytes() == content
    out = capsys.readouterr()
    assert "3 downloaded" in out.out
    assert not (root / ".emu_fetch.lock").exists()


def test_rerun_reports_everything_already_in_place(remote, tmp_path, capsys):
    root = tmp_path / "inputs"
    args = ["inputs", "fetch", "--dir", str(root), "--all"] + _creds(remote)
    assert cli.main(args) == 0
    capsys.readouterr()
    remote.requests.clear()
    assert cli.main(args) == 0
    assert "0 downloaded, 3 already in place, 0 failed" in capsys.readouterr().out
    assert [r.path for r in remote.requests] == [""]  # only the credential check


def test_tools_selection_end_to_end(remote, tmp_path):
    root = tmp_path / "inputs"
    code = cli.main(["inputs", "fetch", "--dir", str(root), "--tools", "msim"] + _creds(remote))
    assert code == 0
    # msim gets only the always-downloaded group here
    assert (root / "forcing/input_init/tile1.mitgrid").exists()
    assert not (root / "emu_ref").exists()


def test_failures_exit_1_and_are_listed(remote, tmp_path, capsys):
    remote.set_fault("remote/emu_ref/YC.data", status=404)
    root = tmp_path / "inputs"
    code = cli.main(["inputs", "fetch", "--dir", str(root), "--all", "--tries", "1"] + _creds(remote))
    assert code == 1
    out = capsys.readouterr().out
    assert "emu_ref/YC.data" in out and "fetch_failures.txt" in out


def test_second_fetch_in_same_dir_exits_2(remote, tmp_path, capsys):
    root = tmp_path / "inputs"
    root.mkdir()
    (root / ".emu_fetch.lock").write_text(
        json.dumps({"pid": os.getpid(), "host": socket.gethostname()}))
    code = cli.main(["inputs", "fetch", "--dir", str(root), "--all"] + _creds(remote))
    assert code == 2
    assert ".emu_fetch.lock" in capsys.readouterr().err
    # Only the credential check reached the server
    assert [r.path for r in remote.requests] == [""]


def test_status_is_a_stub_for_now(tmp_path, capsys):
    code = cli.main(["inputs", "status", "--dir", str(tmp_path)])
    assert code == 2
    assert "not implemented" in capsys.readouterr().err.lower()
