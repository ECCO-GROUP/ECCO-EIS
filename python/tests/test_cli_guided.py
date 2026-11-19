"""Tests for the guided (question-and-answer) mode of `emu inputs fetch`:
in a terminal, missing --dir and --tools/--all are asked for, the built
command is shown, and the user confirms before downloading.
"""

import pytest

from emu import cli
from test_cli_fetch import FILES, _creds, remote  # noqa: F401  (fixture)


@pytest.fixture
def answers(monkeypatch):
    """Feed scripted answers to input() and record the prompts shown."""
    state = {"queue": [], "prompts": []}

    def fake_input(prompt=""):
        state["prompts"].append(prompt)
        if not state["queue"]:
            pytest.fail(f"unexpected prompt: {prompt!r}")
        return state["queue"].pop(0)

    monkeypatch.setattr("builtins.input", fake_input)
    monkeypatch.setattr(cli, "_interactive", lambda: True)

    def give(*items):
        state["queue"].extend(items)
        return state

    return give


def test_guided_mode_asks_for_dir_and_tools_then_downloads(remote, tmp_path, answers, capsys):
    root = tmp_path / "inputs"
    state = answers(str(root), "1", "")  # dir, tool 1 (samp), confirm with Enter
    code = cli.main(["inputs", "fetch"] + _creds(remote))
    assert code == 0
    for path, content in FILES.items():
        assert (root / path).read_bytes() == content

    out = capsys.readouterr().out
    assert "Which EMU tools will you use?" in out
    assert "1) samp" in out and "0) all tools" in out
    assert f"emu inputs fetch --dir {root} --tools samp" in out  # the built command


def test_default_directory_is_used_on_enter(remote, tmp_path, answers, monkeypatch):
    monkeypatch.chdir(tmp_path)
    answers("", "0", "y")  # default dir, all tools, confirm
    assert cli.main(["inputs", "fetch"] + _creds(remote)) == 0
    assert (tmp_path / "emu_input_dir" / "emu_ref" / "XC.data").exists()


def test_given_options_are_not_asked_again(remote, tmp_path, answers, capsys):
    root = tmp_path / "inputs"
    state = answers("1", "y")  # --dir was given: only tools and confirm are asked
    assert cli.main(["inputs", "fetch", "--dir", str(root)] + _creds(remote)) == 0
    assert not any("Directory" in p for p in state["prompts"])


def test_full_options_never_prompt(remote, tmp_path, answers):
    # Every option given: guided mode adds nothing, not even a confirm
    state = answers()
    assert cli.main(["inputs", "fetch", "--dir", str(tmp_path / "in"), "--all"]
                    + _creds(remote)) == 0
    assert state["prompts"] == []


def test_declining_the_confirmation_downloads_nothing(remote, tmp_path, answers, capsys):
    root = tmp_path / "inputs"
    answers(str(root), "1", "n")
    code = cli.main(["inputs", "fetch"] + _creds(remote))
    assert code == 0
    assert not root.exists() or not any(root.rglob("*.data"))
    assert [r.path for r in remote.requests] == []  # not even the credential check
    assert "Not started" in capsys.readouterr().out


def test_invalid_tool_choices_are_asked_again(remote, tmp_path, answers, capsys):
    root = tmp_path / "inputs"
    state = answers(str(root), "9", "1,x", "", "2", "n")
    cli.main(["inputs", "fetch"] + _creds(remote))
    tool_prompts = [p for p in state["prompts"] if "numbers" in p]
    assert len(tool_prompts) == 4  # "9", "1,x" and "" rejected, "2" accepted
    out = capsys.readouterr().out
    assert out.count("Please enter") == 3


def test_several_tools_and_sizes_shown(remote, tmp_path, answers, capsys):
    root = tmp_path / "inputs"
    answers(str(root), "2, 1", "n")  # order and spaces don't matter
    cli.main(["inputs", "fetch"] + _creds(remote))
    out = capsys.readouterr().out
    # Tools are listed in menu order in the built command
    assert "--tools samp,msim" in out
    # The fixture's always group is 1000 B; samp adds 5000 B; msim adds 0
    assert "always included: 0.0 GB" in out
    assert "Selected: samp, msim — 3 files" in out


def test_dir_that_is_a_file_is_asked_again(remote, tmp_path, answers, capsys):
    f = tmp_path / "afile"
    f.write_text("x")
    root = tmp_path / "inputs"
    state = answers(str(f), str(root), "1", "n")
    cli.main(["inputs", "fetch"] + _creds(remote))
    assert sum("Directory" in p for p in state["prompts"]) == 2
    assert "not a directory" in capsys.readouterr().out


def test_not_a_terminal_still_requires_the_options(monkeypatch, capsys):
    monkeypatch.setattr(cli, "_interactive", lambda: False)
    with pytest.raises(SystemExit) as exc_info:
        cli.main(["inputs", "fetch", "--dir", "x"])
    assert exc_info.value.code == 2
    assert "--tools" in capsys.readouterr().err
    with pytest.raises(SystemExit):
        cli.main(["inputs", "fetch", "--all"])
