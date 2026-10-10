"""Voice daemon — wires audio capture, recognition, graph matching, execution, and overlay."""

from __future__ import annotations
import logging
import signal
from pathlib import Path

import gi
gi.require_version("Gst", "1.0")
gi.require_version("GLib", "2.0")
from gi.repository import GLib

from .config_manager import load_config, models_dir
from .command_tree import match, strip_punctuation
from .audio_capture import AudioCapture
from .executor import execute
from .overlay import Overlay
from .whisper_recognizer import WhisperRecognizer


def run_daemon(config_path: Path, headless: bool = False) -> None:
    """Start the voice daemon main loop."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )
    log = logging.getLogger("vox")

    config = load_config(config_path)

    def _build_roots() -> dict[str, tuple[str, list[str]]]:
        roots: dict[str, tuple[str, list[str]]] = {}
        for name, node in config.tree.items():
            if node.type == "root" and node.wake_word:
                roots[name] = (
                    node.wake_word.lower(),
                    [a.lower() for a in node.aliases],
                )
        return roots

    roots = _build_roots()
    log.info("roots: %s", {n: w for n, (w, _) in roots.items()})

    model_path = models_dir() / "ggml-medium.en.bin"
    if not model_path.is_file():
        log.error("Whisper model not found at %s — run install.sh or download manually", model_path)
        return

    overlay = None
    if not headless:
        overlay = Overlay()

    def on_partial(text: str, root_name: str | None = None) -> None:
        log.info("partial: %r (root=%s)", text, root_name)
        if strip_punctuation(text).lower() == "cancel":
            recognizer.reset()
            if overlay:
                overlay.show_text("  Cancelled", timeout=1)
            return
        if overlay:
            if text == "Listening...":
                overlay.show_text(f"  {text}", timeout=2)
            else:
                overlay.show_text(f"  {text}", timeout=0)

    def on_result(text: str, root_name: str | None = None) -> None:
        if not text:
            return
        log.info("result: %r (root=%s)", text, root_name)

        if strip_punctuation(text).lower() == "cancel":
            recognizer.reset()
            if overlay:
                overlay.show_text("  Cancelled", timeout=1)
            return

        results = match(config, text, root_name)
        if results:
            for result in results:
                log.info("matched action_type=%s command=%r text=%r",
                         result.action_type, result.command, result.text)
                try:
                    execute(result.action_type, result.command, config,
                            text=result.text,
                            prefix=result.prefix, suffix=result.suffix)
                    if overlay:
                        cmd_preview = result.command[:60]
                        overlay.show_text(f"{text}\n\u2192 {result.action_type}: {cmd_preview}")
                except Exception as e:
                    log.error("execute failed: %s", e)
                    if overlay:
                        overlay.show_text(f"{text}\n\u26a0 {e}")
        else:
            log.info("no match for: %r", text)
            if overlay:
                overlay.show_text(f"  {text}")

    # ── Config hot-reload ─────────────────────────────────────────────────
    _last_config_mtime = config_path.stat().st_mtime

    def _check_config() -> bool:
        nonlocal config, roots, _last_config_mtime
        try:
            mtime = config_path.stat().st_mtime
            if mtime != _last_config_mtime:
                log.info("config changed, reloading...")
                new_cfg = load_config(config_path)
                config = new_cfg
                roots = _build_roots()
                recognizer.roots = roots
                _last_config_mtime = mtime
                log.info("config reloaded: tree=%d nodes", len(config.tree))
        except Exception as e:
            log.warning("config reload failed: %s", e)
        return True

    # ── End config hot-reload ─────────────────────────────────────────────

    recognizer = WhisperRecognizer(
        model_path=model_path,
        roots=roots,
        on_result=on_result,
        on_partial=on_partial,
    )
    recognizer.start()

    capture = AudioCapture(on_audio=recognizer.feed_audio)
    capture.start()
    log.info("audio capture started, entering main loop")

    loop = GLib.MainLoop()
    GLib.timeout_add_seconds(1, _check_config)

    # ── Watchdog: check whisper-server health every 30s ────────────────
    def _watchdog() -> bool:
        if not recognizer.health_check():
            log.warning("whisper-server unresponsive, restarting...")
            try:
                recognizer.restart()
            except Exception as e:
                log.error("watchdog restart failed: %s", e)
        return True

    GLib.timeout_add_seconds(30, _watchdog)
    # ────────────────────────────────────────────────────────────────────

    def sigint_handler(*_args):
        capture.stop()
        recognizer.stop()
        if overlay:
            overlay.destroy()
        loop.quit()

    signal.signal(signal.SIGINT, sigint_handler)
    signal.signal(signal.SIGTERM, sigint_handler)

    try:
        loop.run()
    except KeyboardInterrupt:
        pass
    finally:
        capture.stop()
        recognizer.stop()
        if overlay:
            overlay.destroy()
