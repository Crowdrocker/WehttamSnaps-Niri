# Config Watcher Setup Guide

Real-time config validation with desktop notifications.

---

## 🎯 What It Does

The config watcher monitors your configuration files and validates them in real-time:

- ✅ **Watches** Niri, Ghostty, and Noctalia configs
- ✅ **Validates** syntax when you save files
- ✅ **Notifies** you immediately if there are errors
- ✅ **Plays** J.A.R.V.I.S. warning sound on critical errors
- ✅ **Logs** all validation events for debugging

**Example notifications:**
- `✓ Niri Config Valid` - Green notification, success sound
- `✗ Niri Config Error: Expected '}' at line 42` - Red notification, warning sound

---

## 📦 Installation

### 1. Install Dependencies

```bash
paru -S inotify-tools
```

### 2. Make Script Executable

```bash
chmod +x ~/.config/wehttamsnaps/scripts/config-watcher.sh
```

### 3. Test It

```bash
# Start watcher
~/.config/wehttamsnaps/scripts/config-watcher.sh start

# In another terminal, edit a config
kate ~/.config/niri/config.kdl

# Make a small change and save - you should see a notification!
```

---

## 🚀 Autostart (Option 1: Niri Spawn)

Add to `~/.config/niri/conf.d/00-base.kdl`:

```kdl
// Config watcher for real-time validation
spawn-at-startup "bash" "-c" "~/.config/wehttamsnaps/scripts/config-watcher.sh start &"
```

Reload Niri:
```bash
niri msg action reload-config
```

---

## 🔧 Autostart (Option 2: Systemd Service)

For more robust process management:

### 1. Create Service File

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/config-watcher.service
```

Add:
```ini
[Unit]
Description=WehttamSnaps Config Watcher
Documentation=https://github.com/Crowdrocker
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/bash %h/.config/wehttamsnaps/scripts/config-watcher.sh start
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

### 2. Enable and Start

```bash
# Reload systemd
systemctl --user daemon-reload

# Enable on boot
systemctl --user enable config-watcher.service

# Start now
systemctl --user start config-watcher.service

# Check status
systemctl --user status config-watcher.service
```

---

## ⌨️ Add Keybind for Manual Validation

Add to `~/.config/niri/conf.d/10-keybinds.kdl`:

```kdl
// Validate all configs manually
Mod+Alt+V { spawn "sh" "-c" "~/.config/wehttamsnaps/scripts/config-watcher.sh validate"; }
```

Reload Niri, then use `Mod + Alt + V` to validate all configs on demand.

---

## 🎨 Add Alias

Add to your shell aliases (already in `.aliases` file):

```bash
# Config validation
alias validate-config='~/.config/wehttamsnaps/scripts/config-watcher.sh validate'
alias watch-config='~/.config/wehttamsnaps/scripts/config-watcher.sh start'
```

---

## 📋 Usage

### Start Watcher

```bash
# Via script
~/.config/wehttamsnaps/scripts/config-watcher.sh start

# Via systemd
systemctl --user start config-watcher.service

# Runs automatically on boot if configured
```

### Stop Watcher

```bash
# Via script
~/.config/wehttamsnaps/scripts/config-watcher.sh stop

# Via systemd
systemctl --user stop config-watcher.service
```

### Check Status

```bash
# Via script
~/.config/wehttamsnaps/scripts/config-watcher.sh status

# Via systemd
systemctl --user status config-watcher.service
```

### Validate All Configs

```bash
# Via script
~/.config/wehttamsnaps/scripts/config-watcher.sh validate

# Via keybind
Mod + Alt + V

# Via alias
validate-config
```

### Test Notifications

```bash
~/.config/wehttamsnaps/scripts/config-watcher.sh test
```

### View Logs

```bash
# Script logs
~/.config/wehttamsnaps/scripts/config-watcher.sh logs

# Or directly
tail -f ~/.cache/wehttamsnaps/config-watcher.log

# Systemd logs
journalctl --user -u config-watcher.service -f
```

---

## 🔍 What Gets Watched

| Location | Files | Validator |
|----------|-------|-----------|
| `~/.config/niri/` | All `.kdl` files | `niri validate` |
| `~/.config/ghostty/` | `config` | Syntax checker |
| `~/.config/quickshell/noctalia/` | All files | Basic checks |

**Events monitored:**
- File modifications (when you save)
- File creation (new configs)
- File deletion (removed configs)
- File moves (renamed configs)

---

## 📱 Notification Types

### Success (Green)
```
✓ Niri Config Valid
Configuration validated successfully
```

### Error (Red + Warning Sound)
```
✗ Niri Config Error
Expected '}' at line 42
  --> config.kdl:42:1
```

### Info (Blue)
```
Config Watcher Started
Monitoring configs for changes
```

---

## 🎯 Example Workflow

**1. Start editing a config:**
```bash
kate ~/.config/niri/config.kdl
```

**2. Make changes and save**

**3. Get instant feedback:**
- ✅ If valid: Green notification "✓ Niri Config Valid"
- ❌ If error: Red notification with error details + J.A.R.V.I.S. warning

**4. Fix errors if needed**

**5. Save again - get success notification**

**6. Reload config with confidence:**
```bash
Mod + Shift + Ctrl + R
```

---

## 🐛 Troubleshooting

### No Notifications Appearing

**Check notification daemon:**
```bash
# Check if mako or dunst is running
ps aux | grep -E "mako|dunst|notification"

# Or use Noctalia's built-in notifications (should work automatically)
```

**Test notifications:**
```bash
notify-send "Test" "This is a test notification"
```

### Watcher Not Starting

**Check dependencies:**
```bash
which inotifywait
# If not found: paru -S inotify-tools
```

**Check logs:**
```bash
tail -f ~/.cache/wehttamsnaps/config-watcher.log
```

**Try starting manually:**
```bash
~/.config/wehttamsnaps/scripts/config-watcher.sh start
# Watch terminal output for errors
```

### Validation Not Working

**Check validators are installed:**
```bash
which niri
niri validate
```

**Test validation manually:**
```bash
~/.config/wehttamsnaps/scripts/config-watcher.sh validate
```

### Too Many Notifications

**Adjust notification urgency in script:**
```bash
# Edit script, change line:
notify "normal" "✓ Niri Config Valid" ...

# To:
# notify "low" "✓ Niri Config Valid" ...
```

Or comment out success notifications entirely if you only want errors.

---

## 🎨 Customization

### Watch Additional Directories

Edit `config-watcher.sh`, add:

```bash
# In start_watcher() function, add:
if [[ -d "$HOME/.config/myapp" ]]; then
    watch_directory "$HOME/.config/myapp" "MyApp Configs" &
fi
```

### Change Notification Duration

```bash
# Edit notify() function:
notify-send -t 5000 ...  # 5 seconds instead of default
```

### Disable J.A.R.V.I.S. Warning Sound

```bash
# Comment out in notify() function:
# if [[ "$urgency" == "critical" ]] && [[ -x "$HOME/.config/wehttamsnaps/scripts/jarvis-manager.sh" ]]; then
#     "$HOME/.config/wehttamsnaps/scripts/jarvis-manager.sh" warning &> /dev/null &
# fi
```

### Add Custom Validators

```bash
# In validate_config() function, add:
elif [[ "$file" == *myapp* ]]; then
    validate_myapp "$file"
```

Then create `validate_myapp()` function.

---

## 💡 Pro Tips

1. **Start watcher on boot** - Never miss a config error
2. **Use keybind** - `Mod + Alt + V` for quick validation
3. **Check logs** - If watcher stops, check logs for why
4. **Test first** - Use `test` command to verify notifications work
5. **Watch terminal** - Run in terminal first to see what's happening

---

## 📚 Integration with Editors

### Kate (KDE Text Editor)

Kate auto-saves, so notifications happen immediately:
- File → Settings → Configure Kate → Application
- ✅ Enable "Save files automatically"

### VS Code

Add auto-save:
```json
{
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000
}
```

### Neovim

Add to `init.vim`:
```vim
" Auto-save on buffer change
autocmd TextChanged,TextChangedI * silent! write
```

---

## 🔗 Related Commands

```bash
# Config watcher
watch-config              # Start watcher
validate-config           # Validate all now

# Niri
niri validate             # Validate Niri only
niri-reload               # Reload Niri config

# Logs
tail -f ~/.cache/wehttamsnaps/config-watcher.log
journalctl --user -u config-watcher.service -f
```

---

## 📝 Quick Reference

### Commands
```bash
config-watcher.sh start      # Start watching
config-watcher.sh stop       # Stop watching
config-watcher.sh status     # Check status
config-watcher.sh validate   # Validate all
config-watcher.sh test       # Test notifications
config-watcher.sh logs       # Show logs
```

### Keybinds
```
Mod + Alt + V     Validate all configs
```

### Systemd
```bash
systemctl --user start config-watcher.service
systemctl --user stop config-watcher.service
systemctl --user status config-watcher.service
systemctl --user restart config-watcher.service
```

---

## 🎉 You're Set!

Now you'll get instant feedback when editing configs:

✅ **Save config** → ✅ **Get notification** → ✅ **Fix errors** → ✅ **Save again** → ✅ **Success!**

No more broken configs! The watcher catches errors before you reload Niri.

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation
