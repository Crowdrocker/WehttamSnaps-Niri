"""Execute matched voice commands — ``exec``, ``shell_exec``, and ``type`` actions."""

from __future__ import annotations
import subprocess
import shlex
import shutil
from urllib.parse import quote as url_quote
from .models import Config


def execute(
    action_type: str, command: str, config: Config,
    text: str | None = None,
    prefix: str = "", suffix: str = "",
) -> None:
    """Execute a matched action.

    Args:
        action_type: ``"exec"``, ``"shell_exec``, or ``"type"``.
        command: The command template (may contain ``{text}`` or ``{url_text}``).
        config: The full config (used to find the terminal for ``shell_exec``).
        text: Captured utterance text, or ``None``.
        prefix: String prepended to the final command.
        suffix: String appended to the final command.

    Placeholders in *command*:
        ``{text}`` — plain substitution (no shell quoting — the template
        is responsible for its own quoting).
        ``{url_text}`` — URL-encoded (percent-encoded) substitution.
    """
    cmd = command

    # Substitute captured text into the command template.
    if text is not None:
        cmd = cmd.replace("{url_text}", url_quote(text, safe=""))
        cmd = cmd.replace("{text}", text)

    # Apply prefix/suffix modifiers.
    if prefix:
        cmd = prefix + " " + cmd
    if suffix:
        cmd = cmd + " " + suffix

    if action_type == "exec":
        if config.exec_prefix:
            cmd = config.exec_prefix + " " + cmd
        subprocess.Popen(cmd, shell=True)

    elif action_type == "shell_exec":
        term_parts = shlex.split(config.terminal)
        subprocess.Popen([*term_parts, "bash", "-c", cmd])

    elif action_type == "type":
        if shutil.which("ydotool"):
            subprocess.run(["ydotool", "type", cmd])
        else:
            raise RuntimeError("ydotool not found, install it for typing support")

    else:
        raise ValueError(f"Unknown action type: {action_type}")
