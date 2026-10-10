# WehttamSnaps OBS Scene Templates Guide

## 📋 Scene Collection Overview

Your streaming setup includes 7 essential scenes optimized for your workflow.

---

## 🎮 1. GAMING (Main Scene)

**Purpose:** Primary gameplay streaming

**Sources to Add:**
1. **Screen Capture (PipeWire)**
   - Add → Screen Capture (PipeWire)
   - Select your game window or full screen
   - Shortcut: **F1**

2. **Webcam**
   - Add → Video Capture Device (V4L2)
   - Device: HD Webcam C615
   - Position: Bottom-right corner (420x240)
   - Optional: Add Chroma Key filter for green screen

3. **Audio Sources:**
   - Game Audio → From `game_audio_source`
   - Microphone → From `HD Webcam C615`
   - Discord → From `discord_audio_source` (muted by default)

**Audio Filters to Add:**
- Microphone → Noise Suppression (RNNoise)
- Microphone → Noise Gate (-40dB threshold)
- Microphone → Compressor (Ratio 3:1)

---

## 🎥 2. STARTING SOON

**Purpose:** Pre-stream countdown with social media

**Sources to Add:**
1. **Background**
   - Option A: Animated background video (loop it)
   - Option B: Static image with gradient
   - Option C: Solid color (#1e1e2e)

2. **Text Elements:**
   - **Main:** "STARTING SOON" (Fira Code, 120pt, #89b4fa)
   - **Countdown:** "5:00" (Fira Code, 80pt, #f38ba8)
   - **Socials:**
     ```
     📺 twitch.tv/WehttamSnaps
     🎬 youtube.com/@WehttamSnaps  
     💻 github.com/Crowdrocker
     ```
   - Position everything centered

3. **Audio:**
   - Music from Spotify/YouTube (via browser_audio_source)
   - Keep at 50% volume

**Shortcut: F2**

---

## 💬 3. JUST CHATTING

**Purpose:** Webcam-focused conversation

**Sources to Add:**
1. **Background**
   - Custom background image or blur effect
   
2. **Webcam (Large)**
   - Full 1280x720, centered
   - Add color correction filter

3. **Chat Widget** (Optional)
   - Browser Source from StreamElements/Streamlabs
   - Position: Right side (400x800)

4. **Stream Title**
   - Text: "WehttamSnaps"
   - Subtitle: "Photography • Gaming • Content"

**Shortcut: F3**

---

## ⏸️ 4. BE RIGHT BACK

**Purpose:** AFK/Bathroom/Food breaks

**Sources to Add:**
1. **BRB Background**
   - Looping video or animated GIF
   - Or static image with text

2. **Text:**
   - Main: "BE RIGHT BACK" (Fira Code, 100pt, #f9e2af)
   - Sub: "Taking a quick break..." (40pt)

3. **Chat Display** (Optional)
   - Keep chat visible while AFK
   - Center bottom (800x400)

4. **Audio:**
   - Lo-fi music or chill beats
   - No game audio, no mic

**Shortcut: F4**

---

## 🎬 5. ENDING SOON

**Purpose:** Stream outro and thank you

**Sources to Add:**
1. **Outro Background**
   - Animated or static

2. **Text Elements:**
   - "THANKS FOR WATCHING!" (90pt, #89b4fa)
   - "❤️ Follow for more content!"
   - Social media links
   - Stream stats (manual update)

3. **Audio:**
   - Outro music

**Shortcut: F5**

---

## 📸 6. PHOTO REVIEW

**Purpose:** Photography workflow showcase

**Sources to Add:**
1. **Desktop Capture**
   - Full screen capture of GIMP/Darktable/Krita

2. **Webcam (Corner)**
   - Small, bottom-right (380x240)

3. **Software Label**
   - Text showing current software
   - Top-left corner

4. **Audio:**
   - Microphone (commentary)
   - Desktop audio (for tutorials)

**Shortcut: F6**

---

## 🎯 7. TECHNICAL DIFFICULTIES

**Purpose:** Emergency fallback scene

**Sources to Add:**
1. **Background**
   - Solid dark color (#1e1e2e)

2. **Error Message:**
   ```
   ⚠️ TECHNICAL DIFFICULTIES ⚠️
   
   Experiencing some issues...
   We'll be back shortly!
   ```
   
3. **J.A.R.V.I.S. Quote:**
   ```
   "Sir, we're experiencing technical difficulties.
   Rebooting systems..."
   ```

4. **Audio:**
   - Background music only
   - No mic, no game audio

**Shortcut: F12**

---

## 🎨 Quick Setup Checklist

### Step 1: Create Scene Collection
1. Open OBS
2. Scene Collection → New → "WehttamSnaps Streaming"

### Step 2: Create All Scenes
Create 7 scenes with the names above (emoji optional but recommended)

### Step 3: Add Audio Sources Globally
In **Settings → Audio:**
- Desktop Audio → DISABLE (we're using specific captures)
- Mic/Auxiliary Audio → DISABLE

Instead, add audio per scene:
- **Sources → Audio Output Capture (PipeWire)**
  - Name: "Game Audio" → Select `game_audio_source`
  - Name: "Microphone" → Select `HD Webcam C615`
  - Name: "Discord Audio" → Select `discord_audio_source`

### Step 4: Configure Hotkeys
**File → Settings → Hotkeys:**
- Scene 1 (Gaming): **F1**
- Scene 2 (Starting Soon): **F2**
- Scene 3 (Just Chatting): **F3**
- Scene 4 (Be Right Back): **F4**
- Scene 5 (Ending Soon): **F5**
- Scene 6 (Photo Review): **F6**
- Scene 7 (Technical Difficulties): **F12**

**Actions:**
- Start Streaming: **Ctrl+F1**
- Start Recording: **Ctrl+F2**
- Stop Streaming/Recording: **Ctrl+F3**
- Mute Microphone: **Ctrl+M**

### Step 5: Add Transitions
**Studio Mode → Transitions:**
- Default: Fade (300ms)
- Alternative: Swipe (500ms)
- Custom: Stinger transition (if you have video)

---

## 📁 Media Files Structure

Create this folder structure:

```
~/.config/wehttamsnaps/media/
├── backgrounds/
│   ├── starting-soon-loop.mp4
│   ├── brb-loop.mp4
│   ├── ending-loop.mp4
│   └── chat-bg.png
├── overlays/
│   ├── gaming-overlay.png
│   ├── webcam-frame.png
│   └── alerts-overlay.png
├── stingers/
│   └── transition.webm
├── music/
│   ├── pre-stream-playlist/
│   └── brb-music/
└── sounds/
    └── (J.A.R.V.I.S. sounds handled by your script)
```

---

## 🎨 Design Resources

### Free Assets:
- **Backgrounds:** [Pexels](https://pexels.com) (search: "abstract tech")
- **Overlays:** [OWN3D.tv](https://own3d.tv/free-overlays)
- **Stingers:** [Nerd or Die](https://nerdordie.com/free-animated-obs-overlays/)
- **Music:** [StreamBeats by Harris Heller](https://www.streambeats.com/)

### Colors (Catppuccin Mocha):
- Primary: `#89b4fa` (Blue)
- Accent: `#f38ba8` (Pink)
- Success: `#a6e3a1` (Green)
- Warning: `#f9e2af` (Yellow)
- Background: `#1e1e2e` (Base)
- Text: `#cdd6f4` (Text)

### Fonts:
- Primary: **Fira Code** (you already have this!)
- Alternative: **JetBrains Mono**

---

## 🔊 Audio Mixing Levels

Recommended levels in OBS mixer:

| Source | Peak Level | Notes |
|--------|------------|-------|
| Game Audio | -12dB to -6dB | Main audio focus |
| Microphone | -6dB to -3dB | Louder than game |
| Discord | -18dB to -12dB | Background chatter |
| Music | -20dB to -15dB | Subtle background |

**Color Coding:**
- 🟢 Green (-20dB to -9dB) = Perfect
- 🟡 Yellow (-9dB to -3dB) = Good
- 🔴 Red (-3dB to 0dB) = Too loud (reduce!)

---

## 🎯 Pro Tips

1. **Test Everything Before Going Live**
   - Run through all scenes
   - Test audio levels with game audio playing
   - Verify webcam positioning

2. **Save Backups**
   - OBS → Scene Collection → Export
   - Save to `~/.config/wehttamsnaps/obs-backups/`

3. **Create Scene Variants**
   - Gaming + Webcam
   - Gaming (No Webcam)
   - Gaming (Minimal Overlay)

4. **Use Studio Mode**
   - Preview scenes before switching live
   - **Controls → Studio Mode** (or click button)

5. **Add Quick Transitions**
   - Right-click scene → Transition Override
   - Set custom transitions per scene

6. **Dock Chat**
   - View → Docks → Chat
   - Keep Twitch chat visible in OBS

---

## 📺 Stream Settings

**Recommended Settings for Twitch:**

**Output:**
- Encoder: FFMPEG VAAPI (AMD GPU)
- Rate Control: CBR
- Bitrate: 6000 Kbps (1080p60) or 4500 Kbps (1080p30)
- Keyframe Interval: 2 seconds

**Video:**
- Base Resolution: 1920x1080
- Output Resolution: 1920x1080
- FPS: 60 (for gaming) or 30 (for chatting)

**Audio:**
- Sample Rate: 48kHz
- Channels: Stereo

---

## 🔥 Quick Start Workflow

### Pre-Stream (15 min before):
1. Launch audio routing: `~/.config/wehttamsnaps/scripts/audio-routing.sh gaming`
2. Open OBS
3. Switch to **STARTING SOON** (F2)
4. Start streaming
5. Play pre-stream music
6. Set countdown timer

### Going Live:
1. Switch to **GAMING** (F1)
2. Launch game
3. Verify audio levels
4. Start gameplay!

### Taking Break:
1. Switch to **BE RIGHT BACK** (F4)
2. Mute microphone (Ctrl+M)
3. Take your break

### Ending Stream:
1. Switch to **ENDING SOON** (F5)
2. Thank viewers, promote follow
3. Wait 2-3 minutes
4. Stop streaming (Ctrl+F3)

---

**Made with ❤️ for WehttamSnaps**  
Photography • Gaming • Content Creation

Now go create some awesome content! 🎮📸✨