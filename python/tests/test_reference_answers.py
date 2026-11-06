"""Check that the saved reference answer files match misc_test_indiv.sh.

The 8 EMU reference examples feed canned answers to emu.sh (and, for
example 7, to helper scripts) through heredocs in emu/misc_test_indiv.sh.
Those answers are also saved as separate files in
emu/tests/reference/answers/. If a prompt changes and only one copy is
updated, these tests fail.
"""

import re
from pathlib import Path

import pytest

# Repository paths: python/tests/ -> repo root -> emu/
REPO = Path(__file__).resolve().parents[2]
SCRIPT = REPO / "emu" / "misc_test_indiv.sh"
ANSWERS = REPO / "emu" / "tests" / "reference" / "answers"

# Expected answer files, in the order their heredocs appear in the script
EXPECTED_FILES = [
    "1_samp.answers",
    "2_fgrd.answers",
    "3_adj.answers",
    "4_conv.answers",
    "5_trc.answers",
    "6_budg.answers",
    "7_msim.misc_msim_data.answers",
    "7_msim.misc_msim_forcing_oceTAUX.answers",
    "7_msim.misc_msim_forcing_oceTAUY.answers",
    "7_msim.answers",
    "8_atrb.answers",
]


def extract_heredocs(text):
    """Return the body of every `<<EOF ... EOF` heredoc, in order.

    Each body is returned exactly as bash would feed it: every line
    including the last ends with a newline.
    """
    # Match from the line containing <<EOF to the next line that is exactly EOF
    pattern = re.compile(r"<<EOF\n(.*?)^EOF$", re.DOTALL | re.MULTILINE)
    return [m.group(1) for m in pattern.finditer(text)]


def test_script_has_one_heredoc_per_answer_file():
    # The script's heredoc count must equal the number of saved answer files
    heredocs = extract_heredocs(SCRIPT.read_text())
    assert len(heredocs) == len(EXPECTED_FILES)


def test_answers_directory_has_exactly_the_expected_files():
    # No missing and no extra answer files
    present = sorted(p.name for p in ANSWERS.glob("*.answers"))
    assert present == sorted(EXPECTED_FILES)


@pytest.mark.parametrize("index,name", list(enumerate(EXPECTED_FILES)))
def test_answer_file_matches_heredoc(index, name):
    # Each saved file must be byte-for-byte identical to its heredoc body
    heredoc = extract_heredocs(SCRIPT.read_text())[index]
    assert (ANSWERS / name).read_text() == heredoc


def test_extract_heredocs_keeps_blank_lines():
    # A leading blank answer (press ENTER) must survive extraction
    text = "cmd <<EOF\n\n1\nm\nEOF\n"
    assert extract_heredocs(text) == ["\n1\nm\n"]
