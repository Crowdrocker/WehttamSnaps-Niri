"""GStreamer-based audio capture — PipeWire with PulseAudio fallback."""

from __future__ import annotations
import logging
from typing import Callable

import gi
gi.require_version("Gst", "1.0")
from gi.repository import Gst, GLib

Gst.init(None)
log = logging.getLogger("vox")


class AudioCapture:
    """Captures microphone audio as 16 kHz mono S16LE PCM samples.

    The pipeline tries ``pipewiresrc`` first (PipeWire), then falls back
    to ``pulsesrc`` (PulseAudio). Audio is resampled and pushed to an
    ``appsink`` element; each buffer triggers the ``on_audio`` callback.

    Args:
        on_audio: Callback receiving raw PCM ``bytes`` (16 kHz, S16LE, mono).
    """

    def __init__(self, on_audio: Callable[[bytes], None]):
        self.on_audio = on_audio
        self.pipeline = None

    def start(self) -> None:
        """Build and start the GStreamer pipeline."""
        src = Gst.ElementFactory.make("pipewiresrc", "src")
        if src is None:
            src = Gst.ElementFactory.make("pulsesrc", "src")
        if src is None:
            raise RuntimeError("No audio source available — tried pipewiresrc and pulsesrc")

        if hasattr(src, "set_property"):
            src.set_property("do-timestamp", True)

        convert = Gst.ElementFactory.make("audioconvert", "convert")
        resample = Gst.ElementFactory.make("audioresample", "resample")
        capsfilter = Gst.ElementFactory.make("capsfilter", "filter")
        caps = Gst.Caps.from_string("audio/x-raw,format=S16LE,rate=16000,channels=1")
        capsfilter.set_property("caps", caps)

        sink = Gst.ElementFactory.make("appsink", "sink")
        sink.set_property("emit-signals", True)
        sink.set_property("max-buffers", 20)
        sink.set_property("drop", True)

        pipeline = Gst.Pipeline.new("audio-capture")
        pipeline.add(src)
        pipeline.add(convert)
        pipeline.add(resample)
        pipeline.add(capsfilter)
        pipeline.add(sink)

        src.link(convert)
        convert.link(resample)
        resample.link(capsfilter)
        capsfilter.link(sink)

        def on_new_sample(appsink):
            sample = appsink.emit("pull-sample")
            buf = sample.get_buffer()
            result, mapinfo = buf.map(Gst.MapFlags.READ)
            if result:
                self.on_audio(mapinfo.data)
                buf.unmap(mapinfo)
            return Gst.FlowReturn.OK

        sink.connect("new-sample", on_new_sample)
        self.pipeline = pipeline

        # Watch the bus for errors and state changes.
        bus = pipeline.get_bus()
        bus.add_signal_watch()
        bus.connect("message::error", self._on_bus_error)
        bus.connect("message::state-changed", self._on_state_changed)

        pipeline.set_state(Gst.State.PLAYING)

    def _on_bus_error(self, _bus, message) -> None:
        error, dbg = message.parse_error()
        log.error("GStreamer error from %s: %s", message.src.get_name(), error)
        if dbg:
            log.debug("GStreamer debug: %s", dbg)

    def _on_state_changed(self, _bus, message) -> None:
        if message.src == self.pipeline:
            old, new, pending = message.parse_state_changed()
            log.debug("GStreamer pipeline: %s -> %s (pending %s)",
                      old.value_nick, new.value_nick, pending.value_nick)

    def stop(self) -> None:
        """Stop and tear down the GStreamer pipeline."""
        if self.pipeline:
            self.pipeline.set_state(Gst.State.NULL)
            self.pipeline = None
