pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    // Used by UI sliders to avoid overshooting when protection is enabled.
    readonly property real uiMaxSinkVolume: (Config.options?.audio?.protection?.enable ?? false)
        ? ((Config.options?.audio?.protection?.maxAllowed ?? 100) / 100)
        : 1.54
    property string audioTheme: Config.options?.sounds?.theme ?? "freedesktop"
    property real value: sink?.audio.volume ?? 0
    property bool micBeingAccessed: Pipewire.links.values.filter(link =>
        !link.source.isStream && !link.source.isSink && link.target.isStream
    ).length > 0
    function friendlyDeviceName(node) {
        return node ? (node.nickname || node.description || Translation.tr("Unknown")) : Translation.tr("Unknown");
    }
    function appNodeDisplayName(node) {
        if (!node) return Translation.tr("Unknown");
        return (node.properties?.["application.name"] || node.description || node.name || Translation.tr("Unknown"))
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    function _roundVolume(v) {
        return Math.round(v * 1000) / 1000;
    }

    // Controls
    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    function toggleMicMute() {
        if (!Audio.source?.audio) return;
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    // Set sink volume safely. When protection is enabled, large jumps can be rejected as "Illegal increment".
    // To keep UX consistent (click anywhere), we optionally ramp in small steps.
    function setSinkVolume(target, ramp = true) {
        if (!root.sink?.audio) return;

        const protectionEnabled = (Config.options?.audio?.protection?.enable ?? false);
        const maxAllowed = (Config.options?.audio?.protection?.maxAllowed ?? 100) / 100;
        const maxCap = protectionEnabled ? Math.min(maxAllowed, root.hardMaxValue) : root.hardMaxValue;
        const clamped = Math.max(0, Math.min(maxCap, target));

        if (!ramp || !protectionEnabled) {
            root.sink.audio.volume = clamped;
            return;
        }

        root._rampTarget = clamped;
        _rampTimer.restart();
    }

    function incrementVolume() {
        if (!root.sink?.audio) return;
        const currentVolume = root.sink.audio.volume;
        const protectionEnabled = (Config.options?.audio?.protection?.enable ?? false);
        const configuredStep = (Config.options?.audio?.protection?.maxAllowedIncrease ?? 2) / 100;
        const step = protectionEnabled
            ? Math.max(0.005, configuredStep)
            : (currentVolume < 0.1 ? 0.01 : 0.02);

        const maxAllowed = (Config.options?.audio?.protection?.maxAllowed ?? 100) / 100;
        const maxCap = protectionEnabled ? Math.min(maxAllowed, root.hardMaxValue) : root.hardMaxValue;
        const newVolume = Math.min(maxCap, currentVolume + step);
        root.setSinkVolume(newVolume, true);
    }
    
    function decrementVolume() {
        if (!root.sink?.audio) return;
        const currentVolume = root.sink.audio.volume;
        const protectionEnabled = (Config.options?.audio?.protection?.enable ?? false);
        const configuredStep = (Config.options?.audio?.protection?.maxAllowedIncrease ?? 2) / 100;
        const step = protectionEnabled
            ? Math.max(0.005, configuredStep)
            : (currentVolume <= 0.1 ? 0.01 : 0.02);
        root.setSinkVolume(Math.max(0, currentVolume - step), true);
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    // Keep current volume within limits when protection settings change.
    // This ensures the limit is applied live (e.g. user lowers maxAllowed in settings).
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root._applyCurrentProtectionClamp();
        }
    }

    Connections {
        target: Config.options?.audio?.protection ?? null
        function onEnableChanged() { root._applyCurrentProtectionClamp(); }
        function onMaxAllowedChanged() { root._applyCurrentProtectionClamp(); }
    }

    function _applyCurrentProtectionClamp() {
        if (!root.sink?.audio) return;
        if (!(Config.options?.audio?.protection?.enable ?? false)) return;
        const maxAllowed = (Config.options?.audio?.protection?.maxAllowed ?? 100) / 100;
        const cap = Math.min(maxAllowed, root.hardMaxValue);
        const current = root._roundVolume(root.sink.audio.volume);
        if (current > cap)
            root.sink.audio.volume = cap;
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!(Config.options?.audio?.protection?.enable ?? false)) return;
            if (!sink?.audio) return;
            const newVolume = root._roundVolume(sink.audio.volume);

            // Always clamp within maxAllowed/hardMaxValue when protection is enabled.
            const maxAllowed = (Config.options?.audio?.protection?.maxAllowed ?? 100) / 100;
            if (newVolume > Math.min(maxAllowed, root.hardMaxValue)) {
                sink.audio.volume = Math.min(maxAllowed, root.hardMaxValue);
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                lastVolume = root._roundVolume(sink.audio.volume);
                lastReady = true;
                return;
            }

            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = (Config.options?.audio?.protection?.maxAllowedIncrease ?? 2) / 100;
            const epsilon = 0.0005;
            const prev = root._roundVolume(lastVolume);

            if ((newVolume - prev) > (maxAllowedIncrease + epsilon)) {
                sink.audio.volume = prev;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (Math.round(newVolume * 100) / 100 > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = maxAllowed;
            }
            lastVolume = root._roundVolume(sink.audio.volume);
        }
    }

    // Ramp helper (prevents "Illegal increment" when user clicks far away on slider)
    property real _rampTarget: 0
    Timer {
        id: _rampTimer
        interval: 16
        repeat: true
        running: false
        onTriggered: {
            if (!root.sink?.audio) {
                running = false
                return
            }

            const protectionEnabled = (Config.options?.audio?.protection?.enable ?? false)
            if (!protectionEnabled) {
                root.sink.audio.volume = root._rampTarget
                running = false
                return
            }

            const maxStep = (Config.options?.audio?.protection?.maxAllowedIncrease ?? 2) / 100
            // Use a step slightly below the configured limit to avoid floating-point overshoot triggering protection.
            const step = Math.max(0.005, maxStep * 0.9)
            const current = root._roundVolume(root.sink.audio.volume)
            const diff = root._rampTarget - current
            if (Math.abs(diff) <= step) {
                root.sink.audio.volume = root._rampTarget
                running = false
                return
            }
            root.sink.audio.volume = current + Math.sign(diff) * step
        }
    }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        // Try playing .oga first
        let command = [
            "/usr/bin/pw-play",
            ogaPath
        ];
        Quickshell.execDetached(command);

        // Also try playing .ogg (will just fail silently if file doesn't exist)
        command = [
            "/usr/bin/pw-play",
            oggPath
        ];
        Quickshell.execDetached(command);
    }

    // IPC handlers for external control (keybinds, etc.)
    IpcHandler {
        target: "audio"

        function volumeUp(): void {
            root.incrementVolume();
        }

        function volumeDown(): void {
            root.decrementVolume();
        }

        function mute(): void {
            root.toggleMute();
        }

        function micMute(): void {
            root.toggleMicMute();
        }
    }
}
