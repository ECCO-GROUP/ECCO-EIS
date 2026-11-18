"""Command-line entry point for the emu package (`emu` console script).

Only `emu inputs fetch`/`status` exist so far (Phase 1). Other
subcommands are added as later phases are implemented.
"""

import argparse
import sys

from emu import __version__


def build_parser():
    # Top-level parser, with "inputs" as the only subcommand group so far
    parser = argparse.ArgumentParser(prog="emu", description="EMU orchestration tool")
    parser.add_argument("--version", action="version", version=f"emu {__version__}")
    subparsers = parser.add_subparsers(dest="command")

    inputs_parser = subparsers.add_parser("inputs", help="manage EMU input downloads")
    inputs_parser.set_defaults(command_help=inputs_parser.format_help)

    return parser


def main(argv=None):
    # Parse args and dispatch; with no subcommand, print help and exit 0
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.command is None:
        parser.print_help()
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
