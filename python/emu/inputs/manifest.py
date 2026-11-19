"""Parse EMU's input inventory and select/map files for a download.

The inventory (misc_build_inventory.sh's output) lists every file under
emu_input_dir, one per line, as either:
    F|<size>|<md5>|./<path>    (a real file)
    D|||./<path>                (a directory; no size/md5 to carry)

This module turns that into a plain list of InventoryEntry (files only),
picks the subset a given set of EMU tools needs (select_entries), and
maps a selected file's local path to the URL it downloads from (to_url).
"""

from urllib.parse import quote


class InventoryError(Exception):
    """Raised when an inventory file is malformed."""


class UnknownToolError(Exception):
    """Raised when select_entries is asked for a tool with no group entry."""


class InventoryEntry:
    """One file from the inventory: its local path (relative to
    emu_input_dir, no leading "./"), size in bytes, and md5 checksum.
    """

    def __init__(self, path, size, md5):
        self.path = path
        self.size = size
        self.md5 = md5


def parse_inventory(inventory_path):
    """Parse an inventory file into a list of InventoryEntry.

    Directory lines (kind "D") and files named robots.txt are skipped;
    neither is ever downloaded.
    """
    entries = []
    with open(inventory_path) as f:
        for line_number, line in enumerate(f, start=1):
            line = line.rstrip("\n")
            if not line:
                continue
            fields = line.split("|")
            if len(fields) != 4:
                raise InventoryError(
                    f"{inventory_path}:{line_number}: expected 4 fields "
                    f"separated by '|', got {len(fields)}: {line!r}"
                )
            kind, size_text, md5, raw_path = fields
            if kind != "F":
                continue  # directory line; nothing to download

            # Strip the inventory's leading "./" to get a plain relative path
            path = raw_path[2:] if raw_path.startswith("./") else raw_path
            if path.rsplit("/", 1)[-1] == "robots.txt":
                continue

            try:
                size = int(size_text)
            except ValueError:
                raise InventoryError(
                    f"{inventory_path}:{line_number}: non-integer size "
                    f"{size_text!r}: {line!r}"
                )
            entries.append(InventoryEntry(path=path, size=size, md5=md5))
    return entries


def select_entries(entries, release, tools=None, select_all=False):
    """Return the subset of `entries` that a release's `tools` need.

    With select_all=True, every entry is returned regardless of `tools`.
    Otherwise the result is every entry whose path starts with one of
    the release's always_group prefixes, or with one of the prefixes in
    tool_groups for each name in `tools`. Raises UnknownToolError if a
    name in `tools` has no entry in release.tool_groups.
    """
    if select_all:
        return list(entries)

    tools = tools or []
    prefixes = list(release.always_group)
    for tool in tools:
        if tool not in release.tool_groups:
            known = ", ".join(sorted(release.tool_groups))
            raise UnknownToolError(f"Unknown tool '{tool}'. Known tools: {known}")
        prefixes.extend(release.tool_groups[tool])

    # A file is selected if its path is under (or equal to) any selected
    # prefix directory; "under" means the next path character is "/" so
    # that e.g. "emu_ref2" doesn't match prefix "emu_ref".
    selected = []
    for entry in entries:
        for prefix in prefixes:
            if entry.path == prefix or entry.path.startswith(prefix + "/"):
                selected.append(entry)
                break
    return selected


def to_url(path, release):
    """Map a selected file's local path to its full download URL.

    The local path is matched against release.path_map by longest
    matching prefix (so e.g. "forcing/other/flux-forced/input_init" is
    preferred over "forcing/input_init" when both are prefixes of the
    same path but only one actually is one). The part of the path after
    the matched prefix is appended to that prefix's remote directory and
    the whole thing is appended to base_url, with every path segment
    percent-encoded for use in a URL.
    """
    best_prefix = None
    for local_prefix in release.path_map:
        if path == local_prefix or path.startswith(local_prefix + "/"):
            if best_prefix is None or len(local_prefix) > len(best_prefix):
                best_prefix = local_prefix

    if best_prefix is None:
        raise ValueError(f"No path_map entry covers local path {path!r}")

    remote_prefix = release.path_map[best_prefix]
    rest = path[len(best_prefix):].lstrip("/")

    # Quote each path segment separately so "/" stays a separator but
    # spaces, "&", "#", etc. in file names are percent-encoded.
    remote_path = "/".join(
        quote(segment) for segment in f"{remote_prefix}/{rest}".split("/")
    )
    return f"{release.base_url}/{remote_path}"
