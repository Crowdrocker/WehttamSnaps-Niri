# J.A.R.V.I.S. Sound Pack Integration

> "Allow me to introduce myself, I am JARVIS, a virtual artificial intelligence."

This directory contains the complete J.A.R.V.I.S. theme integration for WehttamSnaps' Niri setup.

## 📁 Directory Structure

```
jarvis/
├── sounds/              # All J.A.R.V.I.S. audio files
│   ├── startup.mp3
│   ├── shutdown.mp3
│   ├── notification.mp3
│   ├── warning.mp3
│   ├── gaming.mp3
│   ├── streaming.mp3
│   ├── morning.mp3
│   ├── afternoon.mp3
│   └── evening.mp3
├── scripts/             # Trigger scripts
│   ├── jarvis-startup.sh
│   ├── jarvis-shutdown.sh
│   ├── jarvis-notify.sh
│   ├── jarvis-warning.sh
│   ├── jarvis-gaming.sh
│   └── jarvis-streaming.sh
└── README.md           # This file
```

## 🎵 Sound Files

All sounds created using [101soundboards.com](https://www.101soundboards.com/) with:
- **73296-jarvis-v1-paul-bettany-tts-computer-ai-voice**
- **1023595-idroid-tts-computer-ai-voice**

### Available Sounds

1. **jarvis-startup.mp3**
   - "Allow me to introduce myself, I am JARVIS, a virtual artificial intelligence. All systems are ready for gaming and work."
   - Plays on system startup with time-based greeting

2. **jarvis-shutdown.mp3**
   - "Shutting down. Have a good day, Matthew."
   - Plays before system shutdown

3. **jarvis-notification.mp3**
   - "Matthew, you have a notification."
   - Integrated with dunst for notifications

4. **jarvis-warning.mp3**
   - "Warning: System temperature critical."
   - Triggered by high CPU/GPU temps or low disk space

5. **jarvis-gaming.mp3**
   - "Gaming mode activated. Systems at maximum performance."
   - Plays when gaming mode is enabled

6. **jarvis-streaming.mp3**
   - "Streaming systems online. All feeds operational."
   - Plays when streaming mode is enabled

7. **Time-based greetings**
   - **morning.mp3**: "Good morning, Matthew. All systems operational."
   - **afternoon.mp3**: "Good afternoon, Matthew. All systems operational."
   - **evening.mp3**: "Good evening, Matthew. All systems operational."

## 🚀 Installation

### 1. Place Sound Files

```bash
# Create sounds directory
mkdir -p ~/.config/jarvis/sounds

# Copy your sound files
cp sounds/*.mp3 ~/.config/jarvis/sounds/
```

### 2. Install Scripts

```bash
# Copy scripts
cp scripts/*.sh ~/.config/jarvis/scripts/
chmod +x ~/.config/jarvis/scripts/*.sh
```

### 3. Configure System Integration

The scripts are automatically integrated with:
- Niri startup (via config.kdl)
- Dunst notifications
- System monitoring
- Gaming/streaming mode toggles

## 🎮 Usage

### Startup Sound

Automatically plays when you log in. The greeting changes based on time:
- 5 AM - 11:59 AM: "Good morning"
- 12 PM - 5:59 PM: "Good afternoon"
- 6 PM - 4:59 AM: "Good evening"

### Gaming Mode

```bash
# Activate gaming mode (Mod+G)
~/.config/jarvis/scripts/jarvis-gaming.sh
```

### Streaming Mode

```bash
# Activate streaming mode (Mod+Shift+S)
~/.config/jarvis/scripts/jarvis-streaming.sh
```

### Manual Playback

```bash
# Play any sound manually
mpv ~/.config/jarvis/sounds/notification.mp3
```

## 🔧 Customization

### Adding New Sounds

1. Create your sound at [101soundboards.com](https://www.101soundboards.com/)
2. Download as MP3
3. Place in `~/.config/jarvis/sounds/`
4. Create a trigger script in `~/.config/jarvis/scripts/`
5. Add keybinding in `~/.config/niri/keybinds.kdl`

### Adjusting Volume

Edit the scripts and add volume control:

```bash
mpv --volume=50 ~/.config/jarvis/sounds/startup.mp3
```

### Disabling Sounds

Comment out the relevant lines in:
- `~/.config/niri/config.kdl` (startup)
- `~/.config/dunst/dunstrc` (notifications)
- Individual scripts

## 🎨 Integration Points

### Niri Config
```kdl
// In config.kdl
exec-once "~/.config/jarvis/scripts/jarvis-startup.sh"
```

### Dunst Notifications
```ini
# In dunstrc
[urgency_normal]
script = ~/.config/jarvis/scripts/jarvis-notify.sh
```

### System Monitoring
```bash
# Temperature monitoring (runs in background)
~/.config/jarvis/scripts/jarvis-monitor.sh
```

## 📝 Notes

- Requires `mpv` or `paplay` for audio playback
- Sounds are non-blocking (play in background)
- Volume controlled by system audio settings
- Compatible with PipeWire and PulseAudio

## 🎤 Voice Customization

Want different voices or phrases? Visit:
- [101soundboards.com](https://www.101soundboards.com/)
- [Uberduck.ai](https://uberduck.ai/)
- [FakeYou.com](https://fakeyou.com/)

## 🐛 Troubleshooting

### Sound Not Playing

```bash
# Check if mpv is installed
which mpv

# Test sound manually
mpv ~/.config/jarvis/sounds/startup.mp3

# Check audio output
pactl list sinks
```

### Wrong Greeting Time

```bash
# Check system time
date

# Verify timezone
timedatectl
```

### Script Not Executing

```bash
# Make scripts executable
chmod +x ~/.config/jarvis/scripts/*.sh

# Check script errors
bash -x ~/.config/jarvis/scripts/jarvis-startup.sh
```

## 💡 Ideas for More Sounds

- Low battery warning
- Update available notification
- Backup completion
- Screenshot taken
- Screen recording started/stopped
- Workspace switching
- Window focus changes
- Network connected/disconnected

---

**Made with 💜 by WehttamSnaps** | "Just like Tony Stark, but with better taste in colors"