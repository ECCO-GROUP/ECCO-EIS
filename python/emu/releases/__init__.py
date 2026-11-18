"""Load per-release definitions for the emu download engine.

A "release" bundles everything the download engine needs for one ECCO
model version: the base download URL, how local paths map to remote
paths, which files each EMU tool needs, and where the release's file
inventory (with md5s) lives. Each release is a release.json file under
emu/releases/<name>/.
"""

import json
from pathlib import Path


class ReleaseNotFoundError(Exception):
    """Raised when a requested release name has no release.json."""


class Release:
    """One release's definition, read from its release.json."""

    def __init__(self, name, base_url, path_map, always_group, tool_groups, inventory_path):
        self.name = name
        self.base_url = base_url
        self.path_map = path_map
        self.always_group = always_group
        self.tool_groups = tool_groups
        self.inventory_path = inventory_path


# Directory holding one subdirectory per release, each with a release.json
_RELEASES_DIR = Path(__file__).parent


def available_releases():
    """Return the names of every release that has a release.json."""
    # Each release is a subdirectory of releases/ containing release.json
    return sorted(
        p.parent.name for p in _RELEASES_DIR.glob("*/release.json")
    )


def load_release(name):
    """Load and return the Release named `name`.

    Raises ReleaseNotFoundError, listing the available releases, if no
    release.json exists for that name.
    """
    release_file = _RELEASES_DIR / name / "release.json"
    if not release_file.is_file():
        available = ", ".join(available_releases()) or "(none found)"
        raise ReleaseNotFoundError(
            f"Unknown release '{name}'. Available releases: {available}"
        )

    with release_file.open() as f:
        data = json.load(f)

    return Release(
        name=data["name"],
        base_url=data["base_url"],
        path_map=data["path_map"],
        always_group=data["always_group"],
        tool_groups=data["tool_groups"],
        inventory_path=data["inventory_path"],
    )
