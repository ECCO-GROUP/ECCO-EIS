"""Tests for the release loader (emu.releases).

A "release" bundles everything the download engine needs to know about
one ECCO model version: where to download it from, how local paths map
to remote URLs, and which files each EMU tool needs. See release.json
for the v4r4-llc90-flux release's actual data.
"""

import pytest

from emu.releases import ReleaseNotFoundError, load_release


def test_load_known_release_returns_base_url():
    # The release's base_url is the root ECCO Drive URL all downloads
    # are relative to.
    release = load_release("v4r4-llc90-flux")
    assert release.base_url == "https://ecco.jpl.nasa.gov/drive/files/Version4/Release4"


def test_load_known_release_returns_path_map():
    # path_map maps a local directory (relative to emu_input_dir) to the
    # remote directory (relative to base_url) it is downloaded from.
    release = load_release("v4r4-llc90-flux")
    assert release.path_map["emu_ref"] == "other/flux-forced/emu_input/emu_ref"
    assert release.path_map["forcing/other/flux-forced/forcing_weekly"] == (
        "other/flux-forced/forcing_weekly"
    )


def test_load_known_release_returns_tool_groups():
    # tool_groups maps an EMU tool name to the extra path_map keys its
    # files live under, beyond the always-downloaded group. Mapping per
    # the design doc's "Tool -> directory groups" table.
    release = load_release("v4r4-llc90-flux")
    groups = release.tool_groups
    assert groups["samp"] == ["emu_ref"]
    assert groups["budg"] == ["emu_ref"]
    assert groups["conv"] == ["emu_ref"]
    assert set(groups["fgrd"]) == {"emu_ref", "forcing/other/flux-forced/forcing"}
    assert set(groups["adj"]) == {"emu_ref", "forcing/other/flux-forced/forcing"}
    assert groups["msim"] == ["forcing/other/flux-forced/forcing"]
    assert set(groups["trc"]) == {
        "emu_ref",
        "forcing/other/flux-forced/state_weekly",
        "scripts",
    }
    assert "emu_msim/mean_ALL" in groups["atrb"]
    assert "emu_ref" in groups["atrb"]


def test_load_known_release_returns_always_group():
    # always_group lists the path_map keys downloaded regardless of
    # which tools were requested.
    release = load_release("v4r4-llc90-flux")
    always = set(release.always_group)
    assert "forcing/input_init" in always
    assert "forcing/other/flux-forced/forcing_weekly" in always
    assert "forcing/other/flux-forced/mask" in always
    assert "forcing/other/flux-forced/xx" in always
    assert "forcing/other/flux-forced/input_init" in always


def test_load_known_release_returns_inventory_path():
    # inventory_path is where the release's file list (with md5s) lives,
    # relative to the ECCO-EIS repo root.
    release = load_release("v4r4-llc90-flux")
    assert release.inventory_path == "emu/misc_build_inventory.emu_input_dir.txt"


def test_load_unknown_release_raises_with_available_list():
    # An unknown release name is a usage error, not a crash; the message
    # must name the releases that do exist so the user can fix the typo.
    with pytest.raises(ReleaseNotFoundError) as exc_info:
        load_release("v9r9-nonexistent")
    message = str(exc_info.value)
    assert "v9r9-nonexistent" in message
    assert "v4r4-llc90-flux" in message
