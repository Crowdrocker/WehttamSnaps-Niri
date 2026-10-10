"""Command-line interface — ``vox daemon`` and ``vox config`` subcommands."""

from __future__ import annotations
import argparse
from pathlib import Path
from .config_manager import default_config_path


def main() -> None:
    """Parse CLI arguments and dispatch to the appropriate subcommand."""
    parser = argparse.ArgumentParser(prog="vox")
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Path to config.json (default: <install_dir>/config.json)",
    )
    sub = parser.add_subparsers(dest="mode", required=True)

    daemon_p = sub.add_parser("daemon", help="Start the voice daemon")
    daemon_p.add_argument(
        "--headless",
        action="store_true",
        help="Run without the HUD overlay window",
    )

    sub.add_parser("config", help="Open the GTK config editor GUI")

    args = parser.parse_args()
    config_path = args.config or default_config_path()

    if args.mode == "daemon":
        # Lazy import — vosk is only needed for daemon mode.
        from .daemon import run_daemon
        run_daemon(config_path, headless=args.headless)
    elif args.mode == "config":
        from .config_ui import run_config_ui
        run_config_ui(config_path)
