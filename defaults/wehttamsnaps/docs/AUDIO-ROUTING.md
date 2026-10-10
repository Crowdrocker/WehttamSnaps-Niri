# Advanced Audio Routing

## Virtual Sinks Setup
Run: `audio-setup.sh`

Creates:
- **Game** - Game audio
- **Browser** - YouTube/Twitch
- **Discord** - Voice chat
- **Music** - Spotify

## Routing for Streaming

### OBS Setup
1. Add Audio Input Capture
2. Select "Monitor of Game" for game audio
3. Select "Monitor of Browser" for music
4. Select "Discord" for voice

### Desktop Audio (for yourself)
- Route all to your speakers/headphones
- Use pavucontrol to per-app routing

### Quick Shortcuts
- **Mod + A**: Launch qpwgraph
- **Mod + Shift + A**: Reset audio routing

## Saved Layouts
- `~/.config/qpwgraph/layout.qpwgraph` - Your custom routing
- Load with: `qpwgraph ~/.config/qpwgraph/layout.qpwgraph`
