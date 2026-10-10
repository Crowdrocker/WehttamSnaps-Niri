"""Whisper-based speech recognition via whisper-server subprocess + VAD."""

from __future__ import annotations
import json
import logging
import math
import socket
import struct
import subprocess
import tempfile
import time
import wave
from pathlib import Path
from threading import Thread
from typing import Callable
from urllib.request import Request, urlopen
from urllib.error import URLError

import gi
gi.require_version("GLib", "2.0")
from gi.repository import GLib

from .command_tree import strip_punctuation

log = logging.getLogger("vox")

SAMPLE_RATE = 16000
SAMPLE_WIDTH = 2
CHANNELS = 1

VAD_THRESHOLD = 300
SILENCE_SECONDS = 0.8
MIN_SEGMENT_SECONDS = 0.1
PARTIAL_INTERVAL = 0.3
WAKE_TIMEOUT = 3.0

WHISPER_PORT = 18081
INFERENCE_URL = f"http://127.0.0.1:{WHISPER_PORT}/inference"


def _rms(data: bytes) -> float:
    if len(data) < 2:
        return 0.0
    count = len(data) // 2
    fmt = f"<{count}h"
    samples = struct.unpack(fmt, data[:count * 2])
    sq_sum = sum(s * s for s in samples)
    return math.sqrt(sq_sum / count)


class WhisperRecognizer:
    """Captures audio, segments speech via VAD, transcribes via whisper-server.

    During speech, periodic partial transcriptions are produced every
    ``PARTIAL_INTERVAL`` seconds so the user can see live feedback.

    Args:
        model_path: Path to a ``ggml-*.bin`` model file.
        roots: Dict mapping root node name to ``(wake_word, aliases)``.
        on_result: Called with ``(text, root_name)`` on final result.
        on_partial: Called with ``(text, root_name)`` during speech.
    """

    def __init__(
        self,
        model_path: Path,
        roots: dict[str, tuple[str, list[str]]] | None = None,
        on_result: Callable[[str, str | None], None] | None = None,
        on_partial: Callable[[str, str | None], None] | None = None,
    ):
        self.model_path = model_path
        self.roots: dict[str, tuple[str, list[str]]] = roots or {}
        # Lowercase all wake words and aliases.
        self.roots = {
            name: (ww.lower(), [a.lower() for a in als])
            for name, (ww, als) in self.roots.items()
        }
        self.on_result = on_result
        self.on_partial = on_partial

        self._server: subprocess.Popen | None = None
        self._running = False

        self._buf = bytearray()
        self._silence_duration = 0.0
        self._segment_duration = 0.0
        self._speech_active = False
        self._last_partial_time = 0.0
        self._wake_state_start: float | None = None
        self._wake_root: str | None = None

    def start(self) -> None:
        """Launch whisper-server and start processing audio."""
        self._running = True
        self._start_server()
        log.info("whisper-server started on port %d", WHISPER_PORT)

    def _start_server(self) -> None:
        cmd = [
            "whisper-server",
            "-m", str(self.model_path),
            "--port", str(WHISPER_PORT),
            "--no-timestamps",
            "-l", "en",
            "-t", "4",
            "-bo", "1",
        ]
        log.info("starting whisper-server (GPU enabled)...")
        log.debug("cmd: %s", " ".join(cmd))
        self._server = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
        )

        for attempt in range(120):
            time.sleep(1)
            if self._server.poll() is not None:
                err = self._server.stderr.read().decode(errors="replace")
                log.error("whisper-server died on startup: %s", err)
                raise RuntimeError(f"whisper-server failed to start: {err}")
            try:
                s = socket.create_connection(("127.0.0.1", WHISPER_PORT), timeout=2)
                s.close()
                log.info("whisper-server ready after ~%ds", attempt + 1)
                return
            except (OSError, socket.error):
                if attempt > 0 and attempt % 10 == 0:
                    log.info("waiting for whisper-server to load model... (%ds)", attempt + 1)
        log.warning("whisper-server did not respond within 120s, continuing anyway")

    def feed_audio(self, data: bytes) -> None:
        if not self._running:
            return
        self._process_vad(data)

    def _process_vad(self, data: bytes) -> None:
        chunk_sec = len(data) / (SAMPLE_RATE * SAMPLE_WIDTH * CHANNELS)
        rms = _rms(data)

        if rms > VAD_THRESHOLD:
            self._buf.extend(data)
            self._silence_duration = 0.0
            self._segment_duration += chunk_sec
            if not self._speech_active:
                self._speech_active = True
                self._last_partial_time = time.monotonic()
                log.debug("speech started (rms=%.1f)", rms)
            elif self.on_partial and time.monotonic() - self._last_partial_time >= PARTIAL_INTERVAL:
                self._last_partial_time = time.monotonic()
                snapshot = bytes(self._buf)
                Thread(target=self._transcribe, args=(snapshot, True), daemon=True).start()
        else:
            if self._speech_active:
                self._buf.extend(data)
                self._segment_duration += chunk_sec
                self._silence_duration += chunk_sec
                if self._silence_duration >= SILENCE_SECONDS:
                    self._finalize_segment()

    def _finalize_segment(self) -> None:
        if self._segment_duration < MIN_SEGMENT_SECONDS:
            log.debug("segment too short (%.2fs), discarding", self._segment_duration)
            self._reset_vad()
            return

        audio_bytes = bytes(self._buf)
        self._reset_vad()
        Thread(target=self._transcribe, args=(audio_bytes, False), daemon=True).start()

    def _reset_vad(self) -> None:
        self._buf.clear()
        self._silence_duration = 0.0
        self._segment_duration = 0.0
        self._speech_active = False

    def _transcribe(self, audio_bytes: bytes, is_partial: bool) -> None:
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                tmp_path = f.name
                with wave.open(f, "wb") as w:
                    w.setnchannels(CHANNELS)
                    w.setsampwidth(SAMPLE_WIDTH)
                    w.setframerate(SAMPLE_RATE)
                    w.writeframes(audio_bytes)

            with open(tmp_path, "rb") as f:
                data = f.read()

            boundary = b"----boundary123"
            body = (
                b"--" + boundary + b"\r\n"
                b'Content-Disposition: form-data; name="file"; filename="audio.wav"\r\n'
                b"Content-Type: audio/wav\r\n\r\n"
                + data +
                b"\r\n--" + boundary + b"--\r\n"
            )
            req = Request(
                INFERENCE_URL,
                data=body,
                headers={"Content-Type": f"multipart/form-data; boundary={boundary.decode()}"},
            )

            resp = urlopen(req, timeout=30)
            result = json.loads(resp.read())
            text = result.get("text", "").strip()

            Path(tmp_path).unlink(missing_ok=True)

            if not text or text == "[BLANK_AUDIO]":
                return

            self._check_wake_word(text, is_partial)

        except URLError as e:
            log.warning("whisper-server request failed: %s", e)
        except Exception as e:
            log.error("transcription error: %s", e)

    def _strip_wake_word(self, text: str) -> tuple[str | None, str | None]:
        """Check if *text* starts with any root's wake word.

        Returns ``(stripped_text, root_name)`` or ``(None, None)``.
        """
        cleaned = strip_punctuation(text)
        lower = cleaned.lower()
        words = lower.split()
        for root_name, (ww, aliases) in self.roots.items():
            for phrase in [ww] + aliases:
                ww_tokens = phrase.split()
                if not ww_tokens:
                    continue
                if words[:len(ww_tokens)] == ww_tokens:
                    return " ".join(words[len(ww_tokens):]), root_name
        return None, None

    def _check_wake_word(self, text: str, is_partial: bool = False) -> None:
        log.info("transcribed: %r", text)
        rest, root_name = self._strip_wake_word(text)

        if root_name is not None:
            # Wake word found
            if not rest:
                # Just the wake word — enter wake state for the next utterance.
                self._wake_state_start = time.monotonic()
                self._wake_root = root_name
                log.info("wake word detected (%s), listening...", root_name)
                if self.on_partial:
                    GLib.idle_add(self.on_partial, "Listening...", root_name)
                return

            log.info("wake word detected (%s) → %r", root_name, rest)
            cb = self.on_partial if is_partial else self.on_result
            if cb:
                GLib.idle_add(cb, rest, root_name)
            if not is_partial:
                self._wake_state_start = None  # command had wake word, no state needed
            return

        # No wake word in this utterance — check if we are in the wake
        # state (wake word was heard in a recent previous segment).
        if self._wake_state_start is not None:
            elapsed = time.monotonic() - self._wake_state_start
            if elapsed < WAKE_TIMEOUT:
                log.info("wake state active (%s), forwarding: %r", self._wake_root, text)
                cb = self.on_partial if is_partial else self.on_result
                if cb:
                    GLib.idle_add(cb, text, self._wake_root)
                if not is_partial:
                    self._wake_state_start = None  # consume on final result
                return
            else:
                log.debug("wake state expired")
                self._wake_state_start = None

        log.debug("no wake word in: %r", text)

    def reset(self) -> None:
        """Discard any buffered audio and wake state — full reset."""
        self._buf.clear()
        self._silence_duration = 0.0
        self._segment_duration = 0.0
        self._speech_active = False
        self._wake_state_start = None
        self._wake_root = None

    def health_check(self) -> bool:
        """Return True if whisper-server is still responding."""
        try:
            s = socket.create_connection(("127.0.0.1", WHISPER_PORT), timeout=2)
            s.close()
            return True
        except (OSError, socket.error):
            return False

    def restart(self) -> None:
        """Kill and re-launch whisper-server, then reset state."""
        log.info("restarting whisper-server...")
        self.stop()
        self._running = True
        self._start_server()
        log.info("whisper-server restarted")

    def stop(self) -> None:
        self._running = False
        if self._server:
            self._server.terminate()
            try:
                self._server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._server.kill()
                self._server.wait()
            self._server = None
            log.info("whisper-server stopped")
