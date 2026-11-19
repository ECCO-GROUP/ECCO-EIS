"""Command-line entry point for the emu package (`emu` console script).

    emu inputs fetch --dir DIR (--tools samp,trc | --all) [options]
    emu inputs status --dir DIR        (not implemented yet)

Exit codes: 0 everything in place; 1 some files failed or weren't
attempted (listed, and written to DIR/fetch_failures.txt); 2 usage,
credential, connection or lock errors.
"""

import argparse
import base64
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

from emu import __version__
from emu.inputs.fetch import EXIT_FAILURES, EXIT_OK, FAILURES_FILE, fetch
from emu.inputs.manifest import UnknownToolError, parse_inventory, select_entries, to_url
from emu.inputs.state import LockHeldError
from emu.releases import ReleaseNotFoundError, load_release

EXIT_USAGE = 2

ENV_USER = "EMU_EARTHDATA_USER"
ENV_PASSWORD = "EMU_WEBDAV_PASSWORD"

# ECCO-EIS repo root, which inventory_path in release.json is relative to
REPO_ROOT = Path(__file__).resolve().parents[2]


def _positive_int(text):
    # argparse type: an integer >= 1
    value = int(text)
    if value < 1:
        raise argparse.ArgumentTypeError(f"must be at least 1, got {value}")
    return value


def _non_negative_number(text):
    # argparse type: a number >= 0
    value = float(text)
    if value < 0:
        raise argparse.ArgumentTypeError(f"must not be negative, got {text}")
    return value


def _tool_list(text):
    # argparse type: "samp,trc" -> ["samp", "trc"]
    return [t.strip() for t in text.split(",") if t.strip()]


def build_parser():
    # Top level: `emu inputs fetch|status`
    parser = argparse.ArgumentParser(prog="emu", description="EMU orchestration tool")
    parser.add_argument("--version", action="version", version=f"emu {__version__}")
    subparsers = parser.add_subparsers(dest="command")

    inputs = subparsers.add_parser("inputs", help="manage EMU input downloads")
    inputs_sub = inputs.add_subparsers(dest="inputs_command")

    # `emu inputs fetch`
    fetch_p = inputs_sub.add_parser(
        "fetch", help="download EMU input files, resuming and verifying md5s")
    fetch_p.add_argument("--dir", required=True,
                         help="EMU input directory (emu_input_dir); created if missing")
    which = fetch_p.add_mutually_exclusive_group(required=True)
    which.add_argument("--tools", type=_tool_list, metavar="TOOL[,TOOL...]",
                       help="fetch only the files these EMU tools need, e.g. samp,trc")
    which.add_argument("--all", action="store_true", help="fetch every input file")
    fetch_p.add_argument("--release", default="v4r4-llc90-flux",
                         help="ECCO release to fetch (default: %(default)s)")
    fetch_p.add_argument("--jobs", type=_positive_int, default=8,
                         help="downloads in progress at once (default: %(default)s)")
    fetch_p.add_argument("--tries", type=_positive_int, default=5,
                         help="attempts per file (default: %(default)s)")
    fetch_p.add_argument("--log-interval", type=_non_negative_number, default=60,
                         help="seconds between fetch_progress.log lines (default: %(default)s)")
    fetch_p.add_argument("--no-postprocess", action="store_true",
                         help="skip building state_weekly_rev_time_227808 after a trc fetch")
    fetch_p.add_argument("--user", help=f"Earthdata username (else ${ENV_USER}, else prompt)")
    fetch_p.add_argument("--password",
                         help=f"ECCO Drive WebDAV password (else ${ENV_PASSWORD}, else prompt)")

    # `emu inputs status` (Task 10)
    status_p = inputs_sub.add_parser("status", help="show download progress for a directory")
    status_p.add_argument("--dir", required=True, help="EMU input directory")
    status_p.add_argument("--release", default="v4r4-llc90-flux")

    parser._inputs_parser = inputs
    return parser


def get_credentials(args):
    """Return (username, password): from --user/--password, else the
    EMU_EARTHDATA_USER/EMU_WEBDAV_PASSWORD environment variables, else
    an interactive prompt. The WebDAV password is shown as it is typed
    so the user can check it; it is a download-only password.
    """
    user = args.user or os.environ.get(ENV_USER)
    password = args.password or os.environ.get(ENV_PASSWORD)
    if not user:
        user = input("Earthdata username: ").strip()
    if not password:
        password = input("ECCO Drive WebDAV password (not your Earthdata password): ").strip()
    return user, password


def check_credentials(release, auth, opener):
    """Request the release's base URL once, as `wget --spider` does in
    1.2a. Return None if the credentials work, else an error message.
    """
    request = urllib.request.Request(release.base_url.rstrip("/") + "/")
    token = base64.b64encode(f"{auth[0]}:{auth[1]}".encode()).decode()
    request.add_header("Authorization", f"Basic {token}")
    try:
        with opener.open(request, timeout=30):
            return None
    except urllib.error.HTTPError as error:
        error.close()
        if error.code in (401, 403):
            return (f"ECCO Drive rejected the credentials (HTTP {error.code}). Check your "
                    "Earthdata username and your ECCO Drive WebDAV password (not your "
                    "Earthdata password; see https://ecco.jpl.nasa.gov/drive/).")
        return f"Credential check got HTTP {error.code} from {release.base_url}"
    except (urllib.error.URLError, OSError) as error:
        return f"Cannot reach {release.base_url}: {error}"


def run_fetch(args):
    """`emu inputs fetch`: returns the exit code."""
    # Release and file selection come first, so usage errors cost nothing
    try:
        release = load_release(args.release)
    except ReleaseNotFoundError as error:
        print(f"emu: {error}", file=sys.stderr)
        return EXIT_USAGE
    inventory = Path(release.inventory_path)
    if not inventory.is_absolute():
        inventory = REPO_ROOT / inventory
    entries = parse_inventory(inventory)
    try:
        selected = select_entries(entries, release, tools=args.tools, select_all=args.all)
    except UnknownToolError as error:
        print(f"emu: {error}", file=sys.stderr)
        return EXIT_USAGE

    auth = get_credentials(args)
    opener = urllib.request.build_opener()
    problem = check_credentials(release, auth, opener)
    if problem:
        print(f"emu: {problem}", file=sys.stderr)
        return EXIT_USAGE

    root = os.path.abspath(args.dir)
    print(f"Fetching {len(selected):,} files ({sum(e.size for e in selected) / 1e9:.1f} GB) "
          f"of release {release.name} into {root}")
    try:
        summary = fetch(
            selected, lambda path: to_url(path, release), root, auth,
            jobs=args.jobs, tries=args.tries, opener=opener, log_interval=args.log_interval,
        )
    except LockHeldError as error:
        print(f"emu: {error}", file=sys.stderr)
        return EXIT_USAGE

    # Final report
    print(f"{summary.downloaded} downloaded, "
          f"{summary.skipped + summary.verified_existing} already in place, "
          f"{len(summary.failed)} failed")
    if summary.failed:
        print(f"Failed files (also in {os.path.join(root, FAILURES_FILE)}):")
        for result in sorted(summary.failed, key=lambda r: r.path):
            print(f"  {result.path}: {result.error}")
    if summary.interrupted:
        print(f"Interrupted; {summary.not_attempted} files not attempted. "
              "Run the same command again to continue.")
    if summary.exit_code == EXIT_OK:
        print("All files in place.")
    return summary.exit_code


def main(argv=None):
    # Parse args and dispatch to the subcommand
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command is None:
        parser.print_help()
        return EXIT_OK
    if args.inputs_command == "fetch":
        try:
            return run_fetch(args)
        except KeyboardInterrupt:
            print("\nemu: interrupted", file=sys.stderr)
            return EXIT_FAILURES
    if args.inputs_command == "status":
        print("emu: `emu inputs status` is not implemented yet", file=sys.stderr)
        return EXIT_USAGE
    parser._inputs_parser.print_help()
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
