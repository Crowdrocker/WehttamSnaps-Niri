"""Vosk-based offline speech-to-text with wake-word detection.

The model is auto-downloaded from alphacephei.com on first use if not
already present in the ``models/`` directory.
"""

from __future__ import annotations
import json
import logging
import shutil
import urllib.request
import zipfile
from pathlib import Path
from typing import Callable

from vosk import Model, KaldiRecognizer

from .command_tree import strip_punctuation

log = logging.getLogger("vox")

VOSK_MODEL_URL = (
    "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
)
MODEL_DIR_NAME = "vosk-model-small-en-us-0.15"


def ensure_model(models_dir: Path) -> Path:
    """Download and extract the Vosk model if not already present.

    Returns the path to the model directory.
    """
    model_path = models_dir / MODEL_DIR_NAME
    if model_path.is_dir():
        return model_path

    print(f"Downloading Vosk model (~40MB) to {models_dir} ...")
    zip_path = models_dir / "model.zip"
    urllib.request.urlretrieve(VOSK_MODEL_URL, zip_path)
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(models_dir)
    zip_path.unlink()
    print("Model downloaded.")
    return model_path


class Recognizer:
    """Wraps a Vosk ``KaldiRecognizer`` with wake-word and alias detection.

    Args:
        model_path: Path to the extracted Vosk model directory.
        wake_word: The primary wake phrase (e.g. "system command").
        wake_word_aliases: Alternative wake phrases.
        on_result: Called with the wake-word-stripped utterance on final result.
        on_partial: Called with partial transcription text.
    """

    def __init__(
        self,
        model_path: Path,
        wake_word: str,
        wake_word_aliases: list[str] | None = None,
        on_result: Callable[[str], None] | None = None,
        on_partial: Callable[[str], None] | None = None,
    ):
        self.model = Model(str(model_path))
        self.rec = KaldiRecognizer(self.model, 16000)
        self.rec.SetWords(False)

        self.wake_word = wake_word.lower()
        self.aliases = [a.lower() for a in (wake_word_aliases or [])]
        self.on_result = on_result
        self.on_partial = on_partial

    def feed(self, data: bytes) -> None:
        """Feed a raw PCM chunk to the recognizer.

        If Vosk returns a final result, checks for wake word and calls
        ``on_result`` with the stripped utterance. Otherwise, checks for
        wake word in the partial and calls ``on_partial`` with the
        stripped text only when the wake word is present.
        """
        if self.rec.AcceptWaveform(data):
            result = json.loads(self.rec.Result())
            text = result.get("text", "").strip()
            if text:
                log.info("Vosk final: %r", text)
                if self.on_result:
                    self._check_wake_word(text, is_partial=False)
        else:
            partial = json.loads(self.rec.PartialResult())
            ptext = partial.get("partial", "").strip()
            if ptext:
                log.info("Vosk partial: %r", ptext)
                if self.on_partial:
                    self._check_wake_word(ptext, is_partial=True)

    def _strip_wake_word(self, text: str) -> str | None:
        """Return *text* with the wake word/alias stripped, or None if not present."""
        cleaned = strip_punctuation(text)
        lower = cleaned.lower()
        words = lower.split()
        for ww in [self.wake_word] + self.aliases:
            ww_tokens = ww.split()
            if words[:len(ww_tokens)] == ww_tokens:
                return " ".join(words[len(ww_tokens):])
        return None

    def _check_wake_word(self, text: str, is_partial: bool = False) -> None:
        """If *text* starts with a wake word or alias, strip it and emit the rest."""
        rest = self._strip_wake_word(text)
        if not rest:
            log.debug("wake word only (skipped)")
            return
        log.info("wake word detected → %r", rest)
        if is_partial:
            self.on_partial(rest)
        else:
            self.on_result(rest)

    def finish(self) -> None:
        """Flush any remaining audio through the recognizer."""
        final = json.loads(self.rec.FinalResult())
        text = final.get("text", "").strip()
        if text and self.on_result:
            self._check_wake_word(text)
