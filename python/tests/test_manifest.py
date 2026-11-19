"""Tests for emu.inputs.manifest: inventory parsing, tool selection, and
mapping a local file path to its download URL.
"""

from pathlib import Path

import pytest

from emu.inputs.manifest import (
    InventoryError,
    UnknownToolError,
    parse_inventory,
    select_entries,
    to_url,
)
from emu.releases import load_release

FIXTURES = Path(__file__).parent / "fixtures"
SMALL_INVENTORY = FIXTURES / "inventory_small.txt"
REAL_INVENTORY = (
    Path(__file__).parent.parent.parent / "emu" / "misc_build_inventory.emu_input_dir.txt"
)


@pytest.fixture
def release():
    return load_release("v4r4-llc90-flux")


# ---- parsing ----

def test_parse_skips_directory_lines_and_robots_txt():
    # The fixture has 2 D lines and 2 robots.txt F lines; both kinds are
    # skipped, leaving only real downloadable files.
    entries = parse_inventory(SMALL_INVENTORY)
    paths = [e.path for e in entries]
    assert not any(p.endswith("robots.txt") for p in paths)
    assert len(entries) == 10


def test_parse_strips_leading_dot_slash():
    # Inventory paths are written as "./emu_ref/XC.data"; parsed entries
    # should hold the path without the leading "./".
    entries = parse_inventory(SMALL_INVENTORY)
    assert any(e.path == "emu_ref/XC.data" for e in entries)
    assert not any(e.path.startswith("./") for e in entries)


def test_parse_sizes_are_ints():
    # The inventory's size field is text; parsed entries must hold it as
    # a real int, not a string, so later size checks can use arithmetic.
    entries = parse_inventory(SMALL_INVENTORY)
    xc = next(e for e in entries if e.path == "emu_ref/XC.data")
    assert xc.size == 100
    assert isinstance(xc.size, int)


def test_parse_keeps_md5():
    entries = parse_inventory(SMALL_INVENTORY)
    xc = next(e for e in entries if e.path == "emu_ref/XC.data")
    assert xc.md5 == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"


def test_parse_malformed_line_raises_with_line_number(tmp_path):
    # A line with the wrong number of fields is a corrupt inventory, not
    # something to silently skip; the error must say which line.
    bad = tmp_path / "bad.txt"
    bad.write_text("D|||.\nF|100|aaaa|./ok.data\nthis line has no pipes\n")
    with pytest.raises(InventoryError) as exc_info:
        parse_inventory(bad)
    assert f"{bad}:3:" in str(exc_info.value)


def test_parse_non_integer_size_raises_with_line_number(tmp_path):
    bad = tmp_path / "bad.txt"
    bad.write_text("F|100|aaaa|./ok.data\nF|big|bbbb|./bad.data\n")
    with pytest.raises(InventoryError) as exc_info:
        parse_inventory(bad)
    assert f"{bad}:2:" in str(exc_info.value)


def test_parse_real_inventory_file_count():
    # Sanity check against the actual EMU inventory: 157,618 F lines
    # minus the 3 robots.txt files.
    entries = parse_inventory(REAL_INVENTORY)
    assert len(entries) == 157_615


def test_parse_real_inventory_total_size():
    # The design doc records the true inputs total about 1.12 TB.
    entries = parse_inventory(REAL_INVENTORY)
    total_gb = sum(e.size for e in entries) / 1e9
    assert 1100 < total_gb < 1140


# ---- selection ----

def test_select_tool_samp_gets_always_group_plus_emu_ref(release):
    entries = parse_inventory(SMALL_INVENTORY)
    selected = {e.path for e in select_entries(entries, release, tools=["samp"])}
    assert selected == {
        "emu_ref/XC.data",
        "emu_ref/YC.data",
        "forcing/input_init/tile003.mitgrid",
        "forcing/other/flux-forced/input_init/weights_ones.data",
        "forcing/other/flux-forced/forcing_weekly/tauu_weekly_v1.0000000168.data",
        "forcing/other/flux-forced/mask/arctic.msk",
        "forcing/other/flux-forced/xx/xx_tauu.0000000129.data",
    }


def test_select_tool_trc_adds_state_weekly_and_scripts(release):
    # trc needs emu_ref (shared with samp) plus state_weekly and scripts.
    entries = parse_inventory(SMALL_INVENTORY)
    selected = {e.path for e in select_entries(entries, release, tools=["trc"])}
    assert "forcing/other/flux-forced/state_weekly/Convtave.0000000168.data" in selected
    assert "scripts/reverseintime_all.sh" in selected
    assert "emu_ref/XC.data" in selected  # trc also needs emu_ref


ALWAYS = {
    "forcing/input_init/tile003.mitgrid",
    "forcing/other/flux-forced/input_init/weights_ones.data",
    "forcing/other/flux-forced/forcing_weekly/tauu_weekly_v1.0000000168.data",
    "forcing/other/flux-forced/mask/arctic.msk",
    "forcing/other/flux-forced/xx/xx_tauu.0000000129.data",
}
EMU_REF = {"emu_ref/XC.data", "emu_ref/YC.data"}
STATE_WEEKLY = {"forcing/other/flux-forced/state_weekly/Convtave.0000000168.data"}
SCRIPTS = {"scripts/reverseintime_all.sh"}
MSIM = {"emu_msim/mean_ALL/diags/weird file & name#1.data"}


@pytest.mark.parametrize(
    "tool,expected",
    [
        ("samp", ALWAYS | EMU_REF),
        ("budg", ALWAYS | EMU_REF),
        ("conv", ALWAYS | EMU_REF),
        # The fixture has no forcing/ files, so fgrd/adj/msim select only
        # what they share with the groups the fixture does contain.
        ("fgrd", ALWAYS | EMU_REF),
        ("adj", ALWAYS | EMU_REF),
        ("msim", ALWAYS),
        ("trc", ALWAYS | EMU_REF | STATE_WEEKLY | SCRIPTS),
        ("atrb", ALWAYS | EMU_REF | MSIM),
    ],
)
def test_select_each_tool_gets_exactly_its_files(release, tool, expected):
    entries = parse_inventory(SMALL_INVENTORY)
    selected = {e.path for e in select_entries(entries, release, tools=[tool])}
    assert selected == expected


def test_select_forcing_tools_get_6hourly_forcing_on_real_inventory(release):
    # The fixture has no forcing/other/flux-forced/forcing/ files; check
    # on the real inventory that fgrd, adj and msim pick them up and the
    # other tools don't.
    entries = parse_inventory(REAL_INVENTORY)
    prefix = "forcing/other/flux-forced/forcing/"
    for tool in ["fgrd", "adj", "msim"]:
        selected = select_entries(entries, release, tools=[tool])
        assert any(e.path.startswith(prefix) for e in selected), tool
    for tool in ["samp", "budg", "conv", "trc", "atrb"]:
        selected = select_entries(entries, release, tools=[tool])
        assert not any(e.path.startswith(prefix) for e in selected), tool


def test_select_all_returns_every_entry(release):
    entries = parse_inventory(SMALL_INVENTORY)
    selected = select_entries(entries, release, select_all=True)
    assert len(selected) == len(entries)


def test_select_unknown_tool_raises(release):
    entries = parse_inventory(SMALL_INVENTORY)
    with pytest.raises(UnknownToolError) as exc_info:
        select_entries(entries, release, tools=["notatool"])
    message = str(exc_info.value)
    assert "notatool" in message
    assert "samp" in message  # names a real tool so the user can see valid ones


# ---- local path -> URL ----

def test_to_url_short_input_init_prefix(release):
    url = to_url("forcing/input_init/tile003.mitgrid", release)
    assert url == (
        "https://ecco.jpl.nasa.gov/drive/files/Version4/Release4"
        "/input_init/tile003.mitgrid"
    )


def test_to_url_similar_input_init_keys_map_to_their_own_remotes(release):
    # forcing/other/flux-forced/input_init and forcing/input_init end in
    # the same directory name but are separate path_map rows (neither is
    # a prefix of the other); each must resolve to its own remote
    # directory, not the other's.
    url = to_url(
        "forcing/other/flux-forced/input_init/weights_ones.data", release
    )
    assert url == (
        "https://ecco.jpl.nasa.gov/drive/files/Version4/Release4"
        "/other/flux-forced/input_init/weights_ones.data"
    )


def test_to_url_longest_prefix_wins_when_one_prefix_is_a_parent_of_another():
    # Construct a release where one path_map key is itself a parent
    # directory of another key, to directly test the tie-break rule
    # (this situation happens to not arise in the real release.json, but
    # the rule must still be implemented correctly).
    class FakeRelease:
        base_url = "https://example.test"
        path_map = {"a": "remote-a", "a/b": "remote-b"}

    url = to_url("a/b/file.data", FakeRelease())
    assert url == "https://example.test/remote-b/file.data"


def test_to_url_quotes_special_characters(release):
    url = to_url(
        "emu_msim/mean_ALL/diags/weird file & name#1.data", release
    )
    assert " " not in url
    assert "&" not in url
    assert "#" not in url
    assert url.startswith(
        "https://ecco.jpl.nasa.gov/drive/files/Version4/Release4"
        "/other/flux-forced/emu_input/emu_msim/mean_ALL/diags/"
    )
    assert url.endswith("weird%20file%20%26%20name%231.data")


def test_to_url_no_matching_prefix_raises():
    class FakeRelease:
        base_url = "https://example.test"
        path_map = {"a": "remote-a"}

    with pytest.raises(ValueError):
        to_url("nowhere/file.data", FakeRelease())
