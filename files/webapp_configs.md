# WehttamSnaps Webapp Configurations

Pre-configured webapp files for 14 popular services.

---

## 📋 Template File

### `template.webapp`

```bash
# Webapp configuration template
# Copy this file and customize for your needs

WEBAPP_NAME="AppName"
WEBAPP_URL="https://example.com"
WEBAPP_ICON="web-browser"
WEBAPP_BROWSER="brave"  # brave, firefox, or chromium
```

---

## 🌐 Pre-Configured Webapps

### 1. `youtube.webapp`

```bash
# YouTube webapp configuration
# Usage: webapp youtube
# Keybind: Mod + W, Y

WEBAPP_NAME="YouTube"
WEBAPP_URL="https://www.youtube.com"
WEBAPP_ICON="youtube"
WEBAPP_BROWSER="brave"
```

---

### 2. `twitch.webapp`

```bash
# Twitch webapp configuration
# Usage: webapp twitch
# Keybind: Mod + W, T

WEBAPP_NAME="Twitch"
WEBAPP_URL="https://www.twitch.tv"
WEBAPP_ICON="twitch"
WEBAPP_BROWSER="brave"
```

---

### 3. `spotify.webapp`

```bash
# Spotify webapp configuration
# Usage: webapp spotify
# Keybind: Mod + W, S

WEBAPP_NAME="Spotify"
WEBAPP_URL="https://open.spotify.com"
WEBAPP_ICON="spotify"
WEBAPP_BROWSER="brave"
```

---

### 4. `discord.webapp`

```bash
# Discord webapp configuration
# Usage: webapp discord
# Keybind: Mod + W, D

WEBAPP_NAME="Discord"
WEBAPP_URL="https://discord.com/app"
WEBAPP_ICON="discord"
WEBAPP_BROWSER="brave"
```

---

### 5. `gmail.webapp`

```bash
# Gmail webapp configuration
# Usage: webapp gmail
# Keybind: Mod + W, M

WEBAPP_NAME="Gmail"
WEBAPP_URL="https://mail.google.com"
WEBAPP_ICON="mail"
WEBAPP_BROWSER="brave"
```

---

### 6. `github.webapp`

```bash
# GitHub webapp configuration
# Usage: webapp github
# Keybind: Mod + W, G

WEBAPP_NAME="GitHub"
WEBAPP_URL="https://github.com/Crowdrocker"
WEBAPP_ICON="github"
WEBAPP_BROWSER="brave"
```

---

### 7. `calendar.webapp`

```bash
# Google Calendar webapp configuration
# Usage: webapp calendar

WEBAPP_NAME="Calendar"
WEBAPP_URL="https://calendar.google.com"
WEBAPP_ICON="calendar"
WEBAPP_BROWSER="brave"
```

---

### 8. `drive.webapp`

```bash
# Google Drive webapp configuration
# Usage: webapp drive

WEBAPP_NAME="Drive"
WEBAPP_URL="https://drive.google.com"
WEBAPP_ICON="folder-cloud"
WEBAPP_BROWSER="brave"
```

---

### 9. `instagram.webapp`

```bash
# Instagram webapp configuration
# Usage: webapp instagram

WEBAPP_NAME="Instagram"
WEBAPP_URL="https://www.instagram.com"
WEBAPP_ICON="instagram"
WEBAPP_BROWSER="brave"
```

---

### 10. `twitter.webapp` (X)

```bash
# X (Twitter) webapp configuration
# Usage: webapp twitter or webapp x

WEBAPP_NAME="X"
WEBAPP_URL="https://x.com"
WEBAPP_ICON="twitter"
WEBAPP_BROWSER="brave"
```

---

### 11. `reddit.webapp`

```bash
# Reddit webapp configuration
# Usage: webapp reddit

WEBAPP_NAME="Reddit"
WEBAPP_URL="https://www.reddit.com"
WEBAPP_ICON="reddit"
WEBAPP_BROWSER="brave"
```

---

### 12. `netflix.webapp`

```bash
# Netflix webapp configuration
# Usage: webapp netflix

WEBAPP_NAME="Netflix"
WEBAPP_URL="https://www.netflix.com"
WEBAPP_ICON="netflix"
WEBAPP_BROWSER="brave"
```

---

### 13. `notion.webapp`

```bash
# Notion webapp configuration
# Usage: webapp notion

WEBAPP_NAME="Notion"
WEBAPP_URL="https://www.notion.so"
WEBAPP_ICON="notion"
WEBAPP_BROWSER="brave"
```

---

### 14. `chatgpt.webapp`

```bash
# ChatGPT webapp configuration
# Usage: webapp chatgpt

WEBAPP_NAME="ChatGPT"
WEBAPP_URL="https://chat.openai.com"
WEBAPP_ICON="ai"
WEBAPP_BROWSER="brave"
```

---

## 🛠️ Creating Custom Webapps

### Method 1: Use Template

```bash
cd ~/.config/wehttamsnaps/webapps

# Copy template
cp template.webapp myapp.webapp

# Edit
nano myapp.webapp

# Customize:
WEBAPP_NAME="MyApp"
WEBAPP_URL="https://myapp.com"
WEBAPP_ICON="web-browser"
WEBAPP_BROWSER="brave"

# Launch
webapp myapp
```

### Method 2: Use Create Command

```bash
webapp create myapp https://myapp.com web-browser brave
```

---

## ⌨️ Adding Keybinds

To add keybinds for your custom webapp:

### 1. Edit Niri Keybinds

```bash
kate ~/.config/niri/conf.d/10-keybinds.kdl
```

### 2. Add Your Keybind

```kdl
// Custom webapps
Mod+W X { spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/webapp-launcher.sh myapp"; }
```

### 3. Reload Niri

```bash
Mod + Shift + Ctrl + R
# or:
niri msg action reload-config
```

---

## 🎨 Customizing Browser

### Change Browser Per Webapp

Edit the `.webapp` file:

```bash
# Use Firefox instead of Brave
WEBAPP_BROWSER="firefox"

# Use Chromium
WEBAPP_BROWSER="chromium"
```

### Set Global Default

Edit the launcher script:

```bash
kate ~/.config/wehttamsnaps/scripts/webapp-launcher.sh

# Find default browser line and change:
WEBAPP_BROWSER="${WEBAPP_BROWSER:-firefox}"  # Default to Firefox
```

---

## 📂 Directory Structure

```
~/.config/wehttamsnaps/webapps/
├── template.webapp           # Template for new webapps
├── youtube.webapp            # YouTube
├── twitch.webapp             # Twitch
├── spotify.webapp            # Spotify
├── discord.webapp            # Discord
├── gmail.webapp              # Gmail
├── github.webapp             # GitHub
├── calendar.webapp           # Google Calendar
├── drive.webapp              # Google Drive
├── instagram.webapp          # Instagram
├── twitter.webapp            # X (Twitter)
├── reddit.webapp             # Reddit
├── netflix.webapp            # Netflix
├── notion.webapp             # Notion
└── chatgpt.webapp            # ChatGPT

~/.cache/wehttamsnaps/webapps/
├── youtube/                  # YouTube user data
├── twitch/                   # Twitch user data
├── spotify/                  # Spotify user data
└── ...                       # Other webapp caches
```

---

## 🪟 Window Rules

Webapps have dedicated window rules in Niri for workspace assignment.

### Default Assignments

| Webapp | Workspace | Reason |
|--------|-----------|--------|
| YouTube | 7 (Media) | Video content |
| Twitch | 7 (Media) | Streaming content |
| Spotify | 7 (Media) | Music |
| Discord | 6 (Chat) | Communication |
| Gmail | 6 (Chat) | Email |
| GitHub | 2 (Terminal) | Development |

### Custom Window Rules

Edit `~/.config/niri/conf.d/20-rules.kdl`:

```kdl
// Custom webapp rule
window-rule {
    match title="^MyApp - Webapp$"
    match app-id="^myapp-webapp$"
    
    open-on-workspace 7
    default-column-width { proportion 0.7; }
}
```

---

## 🎯 Usage Examples

### Launch Webapp

```bash
# Via command
webapp youtube

# Via alias (if you create one)
alias yt='webapp youtube'
yt

# Via keybind
Mod + W, Y
```

### List All Webapps

```bash
webapp list
# or:
webapp-list
```

### Open in Specific Workspace

```bash
# Launch and it auto-goes to correct workspace
webapp youtube  # Goes to workspace 7 (Media)
webapp discord  # Goes to workspace 6 (Chat)
```

---

## 🔧 Advanced Configuration

### Separate User Profiles

Each webapp gets its own user data directory in `~/.cache/wehttamsnaps/webapps/`.

**Benefits:**
- Separate cookies/sessions
- Independent settings
- No cross-contamination

**Example:** You can be logged into two different YouTube accounts:
- One in regular Brave
- One in YouTube webapp

### Custom Launch Flags

Edit webapp config to add custom browser flags:

```bash
WEBAPP_NAME="YouTube"
WEBAPP_URL="https://www.youtube.com"
WEBAPP_ICON="youtube"
WEBAPP_BROWSER="brave"
WEBAPP_FLAGS="--force-dark-mode --disable-features=Translate"
```

Then modify launcher script to use `$WEBAPP_FLAGS`.

---

## 📱 Mobile-Style Apps

For apps with good mobile sites, use mobile user agent:

```bash
WEBAPP_NAME="Instagram"
WEBAPP_URL="https://www.instagram.com"
WEBAPP_ICON="instagram"
WEBAPP_BROWSER="brave"
WEBAPP_FLAGS="--user-agent='Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)'"
```

---

## 🚀 Quick Commands

```bash
# Launch webapp
webapp youtube

# List available
webapp list

# Create new
webapp create name url icon browser

# Edit existing
kate ~/.config/wehttamsnaps/webapps/youtube.webapp
```

---

## 🎨 Icon Options

Common icon names for webapps:

```bash
# Social
"twitter" "instagram" "facebook" "reddit" "discord"

# Media
"youtube" "twitch" "spotify" "netflix" "prime-video"

# Productivity
"mail" "calendar" "drive" "notion" "github"

# Generic
"web-browser" "internet" "network" "cloud" "folder-cloud"

# Custom
"user-info" "applications-internet" "emblem-web"
```

---

## 💡 Tips

1. **Separate Accounts:** Each webapp has its own cache/cookies
2. **Workspace Assignment:** Webapps auto-open in designated workspaces
3. **Keyboard Control:** Use `Mod + W` prefix for quick access
4. **Browser Choice:** Use Brave for best Wayland support
5. **Custom Icons:** Install icon packs for more options

---

## 🔗 Integration with Niri

Webapps integrate seamlessly:

- ✅ Dedicated window rules
- ✅ Workspace assignment
- ✅ Proper window class
- ✅ System keybinds
- ✅ Native notifications
- ✅ Wayland clipboard

---

## 📚 Resources

- **Brave Webapps:** https://brave.com/
- **Firefox PWAs:** https://addons.mozilla.org/en-US/firefox/addon/pwas-for-firefox/
- **Niri Window Rules:** https://github.com/YaLTeR/niri

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation

**Pre-configured webapps:**
YouTube • Twitch • Spotify • Discord • Gmail • GitHub • Calendar • Drive • Instagram • X • Reddit • Netflix • Notion • ChatGPT
