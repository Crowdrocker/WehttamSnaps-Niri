# Wallpaper Manager Setup Guide

Download wallpapers from Wallhaven API integrated with Noctalia.

---

## 🎨 What It Does

- 🔍 **Search** Wallhaven's massive collection (millions of wallpapers)
- ⬇️ **Download** wallpapers by ID or from search results
- 🎲 **Random** wallpapers in any category
- 📚 **Collections** browse and download entire collections
- 🖼️ **Set** wallpapers instantly via Noctalia
- 🔑 **API Key** optional but recommended for full access

---

## 📦 Installation

### 1. Install Dependencies

```bash
paru -S curl jq
```

### 2. Make Script Executable

```bash
chmod +x ~/.config/wehttamsnaps/scripts/wallpaper-manager.sh
```

### 3. Get Your Wallhaven API Key (Optional but Recommended)

**Why get an API key?**
- ✅ Higher rate limits (no throttling)
- ✅ Access to collections
- ✅ Search your favorites
- ✅ NSFW content (if you want it)
- ✅ Completely free!

**How to get it:**
1. Create free account: https://wallhaven.cc/register
2. Go to settings: https://wallhaven.cc/settings/account
3. Scroll to "API Key" section
4. Copy your API key

### 4. Set Your API Key

```bash
wallpaper-manager.sh set-key YOUR_API_KEY_HERE
```

**Verify it's saved:**
```bash
wallpaper-manager.sh show-key
# Output: API Key: abc1...xyz9
```

---

## 🚀 Quick Start

### Search for Wallpapers

```bash
wallpaper-manager.sh search "nature landscape"
```

**Output:**
```
Found 1247 wallpapers

1  983651 - 1920x1080 - #83a598, #427b58, #1d2021
2  953847 - 2560x1440 - #769164, #394e37, #181e16
3  948234 - 1920x1200 - #5a7c5e, #2d3c2e, #0f120f
...
```

### Download from Search

```bash
wallpaper-manager.sh download-search

# Select number:
Enter wallpaper number to download (or 'all' for all): 2

# Or download all:
Enter wallpaper number to download (or 'all' for all): all
```

### Download by ID

If you know the wallpaper ID:
```bash
wallpaper-manager.sh download 983651
```

### Random Wallpapers

```bash
# 10 random wallpapers
wallpaper-manager.sh random

# 20 random wallpapers
wallpaper-manager.sh random 20
```

### Set as Wallpaper

```bash
# After downloading
wallpaper-manager.sh set ~/.config/wehttamsnaps/wallpapers/983651_1920x1080.jpg

# Or use Noctalia's wallpaper selector
Mod + Shift + W
```

---

## 📚 Advanced Usage

### Search with Filters

```bash
# Search with specific categories
wallpaper-manager.sh search "cyberpunk" 100 100 toplist

# Categories:
# 100 = General only
# 010 = Anime only  
# 001 = People only
# 111 = All (default)

# Purity:
# 100 = SFW only (default)
# 110 = SFW + Sketchy
# 111 = All (requires API key)

# Sorting:
# toplist = Most popular (default)
# random = Random order
# date_added = Newest first
# relevance = Most relevant to query
# views = Most viewed
# favorites = Most favorited
```

**Examples:**
```bash
# Anime wallpapers only
wallpaper-manager.sh search "anime girl" 010 100 toplist

# Nature, newest first
wallpaper-manager.sh search "mountain sunset" 100 100 date_added

# Random cyberpunk
wallpaper-manager.sh search "cyberpunk city" 100 100 random
```

### Browse Collections

```bash
# Browse a user's collections
wallpaper-manager.sh collections username

# Example:
wallpaper-manager.sh collections photographysnaps
```

### List Downloaded Wallpapers

```bash
wallpaper-manager.sh list
```

**Output:**
```
Downloaded wallpapers:

983651_1920x1080.jpg (2.3M)
953847_2560x1440.jpg (4.1M)
948234_1920x1200.jpg (1.8M)

Total: 3 wallpapers
Location: /home/wehttamsnaps/.config/wehttamsnaps/wallpapers
```

### Clean Old Wallpapers

```bash
wallpaper-manager.sh clean
```

---

## ⌨️ Add Shortcuts

### Add to Shell Aliases

Already in `.aliases`:
```bash
alias wallpaper='~/.config/wehttamsnaps/scripts/wallpaper-manager.sh'
alias wp='~/.config/wehttamsnaps/scripts/wallpaper-manager.sh'
alias wallpaper-search='~/.config/wehttamsnaps/scripts/wallpaper-manager.sh search'
alias wallpaper-random='~/.config/wehttamsnaps/scripts/wallpaper-manager.sh random'
```

**Usage:**
```bash
# Short commands
wp search "space nebula"
wp random 10
wp download 983651
```

### Add Keybinds (Optional)

Add to `~/.config/niri/conf.d/10-keybinds.kdl`:

```kdl
// Download random wallpaper
Mod+Ctrl+W { spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/wallpaper-manager.sh random 1 && notify-send 'Random wallpaper downloaded'"; }

// Open wallpaper directory
Mod+Shift+Ctrl+W { spawn "thunar" "$HOME/.config/wehttamsnaps/wallpapers"; }
```

---

## 🎯 Workflow Examples

### Daily Fresh Wallpaper

```bash
# Add to cron or systemd timer
# Download 5 random wallpapers daily

# Cron: (crontab -e)
0 9 * * * ~/.config/wehttamsnaps/scripts/wallpaper-manager.sh random 5
```

### Photography Workflow

```bash
# Search for photography inspiration
wp search "landscape photography" 100 100 toplist

# Download top 10
wp download-search
# Enter: all

# Browse in Noctalia
Mod + Shift + W
```

### Themed Collections

```bash
# Download cyberpunk collection
wp search "cyberpunk neon" 100 100 toplist
wp download-search

# Download nature collection  
wp search "forest waterfall" 100 100 toplist
wp download-search

# Download space collection
wp search "space galaxy stars" 100 100 toplist
wp download-search
```

---

## 🔗 Integration with Noctalia

### Automatic Integration

Wallpapers are downloaded to: `~/.config/wehttamsnaps/wallpapers/`

Noctalia automatically detects wallpapers in this directory!

### Access in Noctalia

```bash
# Open Noctalia wallpaper selector
Mod + Shift + W

# Your downloaded wallpapers appear in the list
# Click to set as wallpaper
```

### Set via Script

```bash
# Set wallpaper through Noctalia IPC
qs -c noctalia-shell ipc call wallpaper set /path/to/wallpaper.jpg
```

---

## 🎨 Wallhaven Categories Explained

### General (100)
- Landscapes
- Architecture
- Technology
- Abstract
- Vehicles
- Nature
- Space

### Anime (010)
- Anime characters
- Manga art
- Japanese animation style
- Anime landscapes

### People (001)
- Photography
- Models
- Portraits
- Artistic photography

### Combined (111)
- All categories
- Broadest search results

---

## 🔐 API Key Benefits

### Without API Key:
- ❌ Rate limited (20 requests per minute)
- ❌ Can't access collections
- ❌ Can't search favorites
- ❌ SFW content only

### With API Key:
- ✅ Higher rate limits (45 requests per minute)
- ✅ Access to collections
- ✅ Search your favorites
- ✅ NSFW content (if enabled)
- ✅ Better search results

**Get your key:** https://wallhaven.cc/settings/account

---

## 📂 File Locations

```
~/.config/wehttamsnaps/
├── wallpaper-config.json        # API key and settings
└── wallpapers/                  # Downloaded wallpapers
    ├── 983651_1920x1080.jpg
    ├── 953847_2560x1440.jpg
    └── ...

~/.cache/wehttamsnaps/wallpapers/
├── last-search.json             # Last search results cache
└── wallpaper-manager.log        # Activity log
```

---

## 🐛 Troubleshooting

### "API Error: Invalid API key"

```bash
# Check your API key
wallpaper-manager.sh show-key

# Re-set it
wallpaper-manager.sh set-key YOUR_NEW_KEY
```

### "curl: command not found"

```bash
paru -S curl
```

### "jq: command not found"

```bash
paru -S jq
```

### Rate Limiting

If you hit rate limits:
1. Get an API key (increases limit from 20 to 45 req/min)
2. Add delays between downloads
3. Download in batches

### Wallpaper Not Setting

```bash
# Check if Noctalia is running
ps aux | grep quickshell

# Try setting manually via Noctalia
Mod + Shift + W

# Or use fallback (swww)
paru -S swww
swww img /path/to/wallpaper.jpg
```

---

## 💡 Pro Tips

1. **Use specific search terms** - "mountain sunset" better than "nature"
2. **Filter by resolution** - Search results show resolution
3. **Download in batches** - Use "all" to download entire search
4. **Create collections** - On Wallhaven website, then download via script
5. **Rate limit aware** - Add `sleep 1` between downloads if needed
6. **Favorites on website** - Star wallpapers on site, search them via API
7. **Use toplist sorting** - Gets the best quality wallpapers
8. **Photography mode** - Search for actual photos: `"photography"` filter
9. **Random exploration** - `random 50` to discover new wallpapers
10. **Clean regularly** - Run `clean` to free up space

---

## 🎨 Popular Search Terms

### Nature
- `landscape photography`
- `mountain sunset`
- `forest waterfall`
- `ocean waves`
- `northern lights aurora`

### Space
- `galaxy nebula`
- `space stars`
- `planet earth`
- `astronaut space`

### Tech/Cyber
- `cyberpunk neon`
- `minimalist technology`
- `circuit board`
- `digital art`

### Abstract
- `geometric patterns`
- `abstract colorful`
- `minimalist`
- `gradient`

### Photography
- `street photography`
- `urban architecture`
- `black and white photography`
- `macro photography`

---

## 🔄 Automated Wallpaper Rotation

### Option 1: Cron Job

```bash
# Edit crontab
crontab -e

# Add line (download 3 random wallpapers daily at 9 AM)
0 9 * * * ~/.config/wehttamsnaps/scripts/wallpaper-manager.sh random 3

# Then use Noctalia's wallpaper automation:
Mod + Alt + W  # Toggle automation
```

### Option 2: Systemd Timer

```bash
# Create timer and service
mkdir -p ~/.config/systemd/user

# Service file
cat > ~/.config/systemd/user/wallpaper-download.service << 'EOF'
[Unit]
Description=Download Random Wallpapers

[Service]
Type=oneshot
ExecStart=%h/.config/wehttamsnaps/scripts/wallpaper-manager.sh random 5
EOF

# Timer file
cat > ~/.config/systemd/user/wallpaper-download.timer << 'EOF'
[Unit]
Description=Daily Wallpaper Download

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable timer
systemctl --user enable --now wallpaper-download.timer
```

---

## 📊 Statistics

Check your collection:
```bash
# Count wallpapers
ls -1 ~/.config/wehttamsnaps/wallpapers/ | wc -l

# Total size
du -sh ~/.config/wehttamsnaps/wallpapers/

# Average file size
du -b ~/.config/wehttamsnaps/wallpapers/* | awk '{total+=$1; count++} END {print total/count/1024/1024 " MB"}'
```

---

## 🌐 Wallhaven Resources

- **Website:** https://wallhaven.cc
- **API Docs:** https://wallhaven.cc/help/api
- **Register:** https://wallhaven.cc/register
- **Settings:** https://wallhaven.cc/settings/account
- **Popular:** https://wallhaven.cc/toplist

---

## 🎯 Quick Reference

```bash
# Setup
wallpaper-manager.sh set-key YOUR_KEY

# Search
wallpaper-manager.sh search "query"

# Download
wallpaper-manager.sh download-search
wallpaper-manager.sh download ID
wallpaper-manager.sh random 10

# Manage
wallpaper-manager.sh list
wallpaper-manager.sh set /path/to/wallpaper.jpg
wallpaper-manager.sh clean

# Collections
wallpaper-manager.sh collections username
```

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation

**Start downloading beautiful wallpapers! 🎨**
