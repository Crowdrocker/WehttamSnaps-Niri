pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons

Singleton {
  id: root

  readonly property var nodes: Pipewire.nodes.values.reduce((acc, node) => {
                                                              if (!node.isStream) {
                                                                if (node.isSink) {
                                                                  acc.sinks.push(node)
                                                                } else if (node.audio) {
                                                                  acc.sources.push(node)
                                                                }
                                                              }
                                                              return acc
                                                            }, {
                                                              "sources": [],
                                                              "sinks": []
                                                            })

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode rawSource: Pipewire.defaultAudioSource
  readonly property PwNode source: (rawSource && !rawSource.isSink && (!rawSource.mediaClass || rawSource.mediaClass.startsWith("Audio/Source"))) ? rawSource : null
  readonly property bool hasInput: !!source
  Component.onCompleted: updateInputVolume()

  readonly property list<PwNode> sinks: nodes.sinks
  readonly property list<PwNode> sources: nodes.sources

  // Volume [0..1] is readonly from outside
  readonly property alias volume: root._volume
  property real _volume: sink?.audio?.volume ?? 0

  readonly property alias muted: root._muted
  property bool _muted: !!sink?.audio?.muted

  // Input volume [0..1] is readonly from outside
  readonly property alias inputVolume: root._inputVolume
  property real _inputVolume: 0

  readonly property alias inputMuted: root._inputMuted
  property bool _inputMuted: !!source?.audio?.muted

  readonly property real stepVolume: Settings.data.audio.volumeStep / 100.0

  function updateInputVolume() {
    if (source && source.audio) {
      var vol = source.audio.volume
      if (vol !== undefined && !isNaN(vol)) {
        root._inputVolume = vol
      } else {
        root._inputVolume = 0
      }
      root._inputMuted = !!source.audio.muted
    } else {
      root._inputVolume = 0
      root._inputMuted = true
    }
  }

  // Update input volume when source property changes
  onSourceChanged: {
    updateInputVolume()
  }

  PwObjectTracker {
    objects: [...root.sinks, ...root.sources]
  }

  Connections {
    target: sink?.audio ? sink?.audio : null

    function onVolumeChanged() {
      var vol = (sink?.audio.volume ?? 0)
      if (isNaN(vol)) {
        return
      }
      // Only update if the value actually changed to prevent spurious signals
      if (Math.abs(root._volume - vol) > 0.001) {
        root._volume = vol
      }
    }

    function onMutedChanged() {
      var newMuted = (sink?.audio.muted ?? true)
      // Only update if the value actually changed
      if (root._muted !== newMuted) {
        root._muted = newMuted
        Logger.i("AudioService", "OnMuteChanged:", root._muted)
      }
    }
  }

  Connections {
    target: source?.audio ? source?.audio : null

    function onVolumeChanged() {
      var vol = source?.audio?.volume
      if (vol === undefined || isNaN(vol)) {
        root._inputVolume = 0
        return
      }
      // Only update if the value actually changed to prevent spurious signals
      if (Math.abs(root._inputVolume - vol) > 0.001) {
        root._inputVolume = vol
      }
    }

    function onMutedChanged() {
      var newMuted = (source?.audio.muted ?? true)
      // Only update if the value actually changed
      if (root._inputMuted !== newMuted) {
        root._inputMuted = newMuted
      }
    }
  }
  Connections {
    target: Pipewire

    function onDefaultAudioSinkChanged() {}

    function onDefaultAudioSourceChanged() {
      updateInputVolume()
    }
  }

  function increaseVolume() {
    setVolume(volume + stepVolume)
  }

  function decreaseVolume() {
    setVolume(volume - stepVolume)
  }

  function setVolume(newVolume: real) {
    if (sink?.ready && sink?.audio) {
      // Clamp it accordingly
      sink.audio.muted = false
      sink.audio.volume = Math.max(0, Math.min(Settings.data.audio.volumeOverdrive ? 1.5 : 1.0, newVolume))
      //Logger.i("AudioService", "SetVolume", sink.audio.volume);
    } else {
      Logger.w("AudioService", "No sink available")
    }
  }

  function setOutputMuted(muted: bool) {
    if (sink?.ready && sink?.audio) {
      sink.audio.muted = muted
    } else {
      Logger.w("AudioService", "No sink available")
    }
  }

  function increaseInputVolume() {
    setInputVolume(inputVolume + stepVolume)
  }

  function decreaseInputVolume() {
    setInputVolume(inputVolume - stepVolume)
  }

  function setInputVolume(newVolume: real) {
    if (source?.ready && source?.audio) {
      // Clamp it accordingly
      source.audio.muted = false
      source.audio.volume = Math.max(0, Math.min(Settings.data.audio.volumeOverdrive ? 1.5 : 1.0, newVolume))
    } else {
      Logger.w("AudioService", "No source available")
    }
  }

  function setInputMuted(muted: bool) {
    if (source?.ready && source?.audio) {
      source.audio.muted = muted
    } else {
      Logger.w("AudioService", "No source available")
    }
  }

  function setAudioSink(newSink: PwNode): void {
    Pipewire.preferredDefaultAudioSink = newSink
    // Volume is changed by the sink change
    root._volume = newSink?.audio?.volume ?? 0
    root._muted = !!newSink?.audio?.muted
  }

  function setAudioSource(newSource: PwNode): void {
    Pipewire.preferredDefaultAudioSource = newSource
    // The source property will update automatically, which triggers onSourceChanged
    // which calls updateInputVolume()
  }

  function getOutputIcon() {
    if (muted) {
      return "volume-mute"
    }
    return (volume <= Number.EPSILON) ? "volume-zero" : (volume <= 0.5) ? "volume-low" : "volume-high"
  }

  function getInputIcon() {
    if (inputMuted) {
      return "microphone-mute"
    }
    return (inputVolume <= Number.EPSILON) ? "microphone-mute" : "microphone"
  }
}
