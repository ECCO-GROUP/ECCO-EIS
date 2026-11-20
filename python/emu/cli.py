"""Command-line entry point for the emu package (`emu` console script).

    emu inputs fetch --dir DIR (--tools samp,trc | --all) [options]
    emu inputs status --dir DIR [--tools ...]   (reports progress; changes nothing)

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
from emu.inputs.fetch import (EXIT_FAILURES, EXIT_OK, FAILURES_FILE, POSTPROCESS_FAILED,
                              POSTPROCESS_LOG, VERIFY_FAILURES_FILE, postprocess,
                              fetch, verify)
from emu.inputs.manifest import UnknownToolError, parse_inventory, select_entries, to_url
from emu.inputs.state import LockHeldError
from emu.inputs.status import collect_status, format_status
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


def _interactive():
    """Whether someone is at a terminal to answer questions."""
    return sys.stdin.isatty() and sys.stdout.isatty()


def build_parser(guided=False):
    # Top level: `emu inputs fetch|status`. With guided=True (a terminal),
    # --dir and --tools/--all may be left out and are asked for instead.
    parser = argparse.ArgumentParser(prog="emu", description="EMU orchestration tool")
    parser.add_argument("--version", action="version", version=f"emu {__version__}")
    subparsers = parser.add_subparsers(dest="command")

    inputs = subparsers.add_parser("inputs", help="manage EMU input downloads")
    inputs_sub = inputs.add_subparsers(dest="inputs_command")

    # `emu inputs fetch`
    fetch_p = inputs_sub.add_parser(
        "fetch", help="download EMU input files, resuming and verifying md5s",
        description="Download EMU input files. Run in a terminal without --dir or "
                    "--tools/--all to be asked for them.")
    fetch_p.add_argument("--dir", required=not guided,
                         help="EMU input directory (emu_input_dir); created if missing")
    which = fetch_p.add_mutually_exclusive_group(required=not guided)
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
    fetch_p.add_argument("--verify-only", action="store_true",
                         help="only re-check md5s of files already on disk; no download, "
                              "no network access, no credentials")
    fetch_p.add_argument("--no-postprocess", action="store_true",
                         help="skip building state_weekly_rev_time_227808 after a trc fetch")
    fetch_p.add_argument("--user", help=f"Earthdata username (else ${ENV_USER}, else prompt)")
    fetch_p.add_argument("--password",
                         help=f"ECCO Drive WebDAV password (else ${ENV_PASSWORD}, else prompt)")

    # `emu inputs status`
    status_p = inputs_sub.add_parser(
        "status", help="show download progress for a directory (changes nothing)")
    status_p.add_argument("--dir", required=True, help="EMU input directory")
    status_p.add_argument("--tools", type=_tool_list, metavar="TOOL[,TOOL...]",
                          help="count only these tools' files (default: all files)")
    status_p.add_argument("--release", default="v4r4-llc90-flux",
                          help="ECCO release (default: %(default)s)")

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


TOOL_MENU = [
    ("samp", "Sampling"),
    ("fgrd", "Forward Gradient"),
    ("adj", "Adjoint"),
    ("conv", "Convolution"),
    ("trc", "Tracer"),
    ("budg", "Budget"),
    ("msim", "Modified Simulation"),
    ("atrb", "Attribution"),
]


def ask_directory(default):
    """Ask for the input directory until the answer is usable."""
    while True:
        answer = input(f"Directory for EMU input files (emu_input_dir)?\n"
                       f"  [default: {default}] > ").strip()
        path = os.path.abspath(os.path.expanduser(answer or default))
        if os.path.exists(path) and not os.path.isdir(path):
            print(f"  {path} exists and is not a directory.")
            continue
        return path


def ask_tools(entries, release):
    """Show each tool's extra download size and ask which to fetch.

    Returns (tools, select_all): a list of tool names in menu order, or
    (None, True) for all tools.
    """
    menu = [(name, label) for name, label in TOOL_MENU if name in release.tool_groups]
    always = select_entries(entries, release, tools=[])
    always_paths = {e.path for e in always}

    # Each tool's size beyond the always-downloaded files
    extra = {}
    for name, _ in menu:
        files = select_entries(entries, release, tools=[name])
        extra[name] = sum(e.size for e in files if e.path not in always_paths)
    total = sum(e.size for e in entries)

    print(f"Which EMU tools will you use? Files each needs "
          f"(always included: {sum(e.size for e in always) / 1e9:.1f} GB):")
    for number, (name, label) in enumerate(menu, start=1):
        print(f"  {number}) {name:<5} {label:<20} +{extra[name] / 1e9:,.1f} GB")
    print(f"  0) all tools{'':<16} {total / 1e9:,.1f} GB")

    while True:
        answer = input("Enter numbers separated by commas (e.g. 1,6) > ").strip()
        try:
            numbers = {int(part) for part in answer.split(",") if part.strip()}
        except ValueError:
            numbers = set()
        if numbers == {0}:
            return None, True
        if numbers and all(1 <= n <= len(menu) for n in numbers):
            return [menu[n - 1][0] for n in sorted(numbers)], False
        print(f"  Please enter one or more of 1-{len(menu)}, or 0 for all tools.")


def built_command(args):
    """The non-interactive command equivalent to the answers given."""
    parts = ["emu", "inputs", "fetch", "--dir", args.dir]
    parts += ["--all"] if args.all else ["--tools", ",".join(args.tools)]
    defaults = build_parser(guided=True).parse_args(["inputs", "fetch"])
    for option in ["release", "jobs", "tries", "log_interval"]:
        if getattr(args, option) != getattr(defaults, option):
            parts += [f"--{option.replace('_', '-')}", str(getattr(args, option))]
    if args.verify_only:
        parts.append("--verify-only")
    if args.no_postprocess:
        parts.append("--no-postprocess")
    return " ".join(parts)


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


def run_status(args):
    """`emu inputs status`: print progress for --dir; returns the exit code."""
    root = os.path.abspath(args.dir)
    if not os.path.isdir(root):
        print(f"emu: {root} does not exist or is not a directory", file=sys.stderr)
        return EXIT_USAGE
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
        selected = select_entries(entries, release, tools=args.tools, select_all=not args.tools)
    except UnknownToolError as error:
        print(f"emu: {error}", file=sys.stderr)
        return EXIT_USAGE
    description = (f"tools {', '.join(args.tools)} of release {release.name}" if args.tools
                   else f"all files of release {release.name}")
    print(f"{root}")
    print(format_status(collect_status(selected, root), description))
    return EXIT_OK


def run_verify(args, selected, guided):
    """`emu inputs fetch --verify-only`: re-check md5s of the selected
    files on disk, with no network access and no credentials.
    """
    root = os.path.abspath(args.dir)
    if not os.path.isdir(root):
        print(f"emu: {root} does not exist or is not a directory", file=sys.stderr)
        return EXIT_USAGE
    if guided:
        print(f"\nThis is the same as running:\n  {built_command(args)}\n")
        if input("Start checking now? [Y/n] > ").strip().lower() not in ("", "y", "yes"):
            print("Not started.")
            return EXIT_OK

    total = sum(e.size for e in selected)
    print(f"Checking {len(selected):,} files ({total / 1e9:,.1f} GB) in {root} "
          "against the inventory md5s (no network access)")
    try:
        summary = verify(selected, root, jobs=args.jobs)
    except LockHeldError as error:
        print(f"emu: {error}", file=sys.stderr)
        return EXIT_USAGE

    print(f"{summary.ok:,} correct, {len(summary.missing):,} missing, "
          f"{len(summary.wrong_size):,} wrong size, {len(summary.wrong_md5):,} wrong md5")
    if summary.problems:
        print(f"Problems (also in {os.path.join(root, VERIFY_FAILURES_FILE)}):")
        for label, items in [("missing", summary.missing), ("wrong size", summary.wrong_size),
                             ("wrong md5", summary.wrong_md5)]:
            for e in sorted(items, key=lambda e: e.path)[:20]:
                print(f"  {label}: {e.path}")
            if len(items) > 20:
                print(f"  ... and {len(items) - 20} more {label}")
        print("Run `emu inputs fetch` without --verify-only to download or repair them.")
    if summary.interrupted:
        print("Interrupted; run the same command again to finish checking.")
    if summary.exit_code == EXIT_OK:
        print("All files correct.")
    return summary.exit_code


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

    # Guided mode: ask for whatever wasn't given on the command line
    guided = args.dir is None or not (args.tools or args.all)
    if guided:
        print(f"\nEMU input download (release {release.name})\n")
        if args.dir is None:
            args.dir = ask_directory(os.path.join(os.getcwd(), "emu_input_dir"))
            print()
        if not (args.tools or args.all):
            args.tools, args.all = ask_tools(entries, release)
            print()

    try:
        selected = select_entries(entries, release, tools=args.tools, select_all=args.all)
    except UnknownToolError as error:
        print(f"emu: {error}", file=sys.stderr)
        return EXIT_USAGE

    if guided:
        names = "all tools" if args.all else ", ".join(args.tools)
        print(f"Selected: {names} — {len(selected):,} files, "
              f"{sum(e.size for e in selected) / 1e9:,.1f} GB")

    if args.verify_only:
        return run_verify(args, selected, guided)

    auth = get_credentials(args)

    if guided:
        print(f"\nThis is the same as running:\n  {built_command(args)}\n"
              "(Use that command to rerun, or under nohup/screen.)\n")
        if input("Start downloading now? [Y/n] > ").strip().lower() not in ("", "y", "yes"):
            print("Not started.")
            return EXIT_OK
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

    # The release's post-fetch step (V4r4: build state_weekly_rev_time_227808
    # for the Tracer Tool), only after a clean fetch and unless switched off
    exit_code = summary.exit_code
    rule = release.postprocess
    wanted = rule and (args.all or rule["tool"] in (args.tools or []))
    if wanted and args.no_postprocess:
        print(f"Skipping {rule['script']} (--no-postprocess).")
    elif wanted and exit_code == EXIT_OK:
        print(f"Running {rule['script']} to build {rule['creates']} ...")
        result = postprocess(release, selected, root, tools=args.tools, select_all=args.all)
        log = os.path.join(root, POSTPROCESS_LOG)
        if result.status == POSTPROCESS_FAILED:
            print(f"emu: post-processing failed: {result.message} (see {log})")
            exit_code = EXIT_FAILURES
        else:
            print(f"Post-processing: {result.status}"
                  + (f" ({result.message})" if result.message else ""))
    return exit_code


def main(argv=None):
    # Write each printed line out at once, so a run under nohup shows its
    # opening lines in the output file straight away, not only at the end
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except (AttributeError, ValueError):
        pass  # replaced stream (e.g. in tests) that can't be reconfigured
    # Parse args and dispatch to the subcommand
    parser = build_parser(guided=_interactive())
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
        return run_status(args)
    parser._inputs_parser.print_help()
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
