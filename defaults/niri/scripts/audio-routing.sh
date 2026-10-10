#!/usr/bin/env bash

# ──────────────────────────────────────────────────────────────────────
# WEHTTAMSNAPS - CUSTOM PIPEWIRE STREAMING & GAMING ROUTER
# ──────────────────────────────────────────────────────────────────────

# Define your real, physical output device name.
# (Script will auto-detect your active headphone sink if left blank)
PHYS_OUTPUT=$(pactl get-default-sink)

echo "🎵 Initializing PipeWire Matrix using target output: $PHYS_OUTPUT"

# Function to safely create a virtual virtual channel (Sink)
create_sink() {
    local name=$1
    local description=$2

    # Unload if it already exists to prevent duplicate channel blocks
    if pactl list short modules | grep -q "sink_name=$name"; then
        pactl unload-module $(pactl list short modules | grep "sink_name=$name" | awk '{print $1}') 2>/dev/null || true
    fi

    # Load the virtual sink module
    pactl load-module module-null-sink \
        sink_name="$name" \
        sink_properties=device.description="$description"
}

# Function to hook up loopbacks so you can hear the virtual channel in your headphones
create_loopback() {
    local source_sink=$1
    pactl load-module module-loopback \
        source="$source_sink.monitor" \
        sink="$PHYS_OUTPUT" \
        latency_msec=1
}

# ──────────────────────────────────────────────────────────────────────
# 1. BUILD VIRTUAL AUDIO CHANNELS
# ──────────────────────────────────────────────────────────────────────
echo "🎛️ Spinning up virtual sinks..."
create_sink "Game_Sink"    "🎮 Game Audio Channel"
create_sink "Music_Sink"   "🎵 Music Channel (Non-Copyright)"
create_sink "Discord_Sink" "💬 Discord / Comms Channel"
create_sink "Jarvis_Sink"  "🤖 J.A.R.V.I.S. System Voice"

# ──────────────────────────────────────────────────────────────────────
# 2. BRIDGING THE CHANNELS TO YOUR HEADPHONES
# ──────────────────────────────────────────────────────────────────────
echo "🎧 Patching loopback bridges to physical monitoring device..."
create_loopback "Game_Sink"
create_loopback "Music_Sink"
create_loopback "Discord_Sink"
create_loopback "Jarvis_Sink"

# ──────────────────────────────────────────────────────────────────────
# 3. PROFILE MANAGER (TRIGGER SCENES)
# ──────────────────────────────────────────────────────────────────────
PROFILE=${1:-"gaming"}

case "$PROFILE" in
    "gaming"|"live")
        echo "⚡ Applying 'Gaming & Streaming' profile..."
        # Max out game and comms clarity, sit music nicely in the back
        pactl set-sink-volume Game_Sink 100%
        pactl set-sink-volume Discord_Sink 100%
        pactl set-sink-volume Music_Sink 65%
        pactl set-sink-volume Jarvis_Sink 90%
        ;;
    "music_only")
        echo "🎹 Applying 'Chilled Focus' profile..."
        pactl set-sink-volume Game_Sink 0%
        pactl set-sink-volume Music_Sink 100%
        pactl set-sink-volume Discord_Sink 50%
        ;;
    *)
        echo "⚠️ Unknown profile request. Keeping default audio balances."
        ;;
esac

echo "✅ Audio routing system successfully mapped!"
