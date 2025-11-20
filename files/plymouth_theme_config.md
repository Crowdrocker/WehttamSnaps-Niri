# Plymouth WehttamSnaps Spinner Theme

## Directory Structure

Create this directory structure in your repository:

```
plymouth/
└── wehttamsnaps-spinner/
    ├── wehttamsnaps-spinner.plymouth
    ├── wehttamsnaps-spinner.script
    ├── logo.png (200x200px - your camera aperture)
    ├── progress_bg.png (300x6px)
    └── progress_fill.png (300x6px)
```

---

## File: `wehttamsnaps-spinner.plymouth`

```ini
[Plymouth Theme]
Name=WehttamSnaps Spinner
Description=Spinning camera aperture logo for WehttamSnaps workstation
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/wehttamsnaps-spinner
ScriptFile=/usr/share/plymouth/themes/wehttamsnaps-spinner/wehttamsnaps-spinner.script
```

---

## Creating the Logo Image

### Option 1: Use Your Camera Aperture Logo

**Requirements:**
- PNG format with transparency
- 200x200 pixels (or will be scaled)
- Centered design works best for spinning
- Save as `logo.png`

**From your images:**
1. Take your camera aperture logo (Image 1 from our conversation)
2. Resize to 200x200px: `convert logo-original.png -resize 200x200 logo.png`
3. Ensure it's centered and has transparent background

### Option 2: Create Simple Aperture in GIMP

```bash
# Install GIMP if needed
paru -S gimp

# Create 200x200 canvas
# Add → Layer → Transparency
# Use polygon tool to draw aperture blades (6-8 blades)
# Export as logo.png with transparency
```

---

## Creating Progress Bar Images

### `progress_bg.png` (Background - 300x6px)

```bash
# Create dark gray background bar
convert -size 300x6 xc:"#313244" progress_bg.png
```

### `progress_fill.png` (Fill - 300x6px)

```bash
# Create blue fill bar (WehttamSnaps color)
convert -size 300x6 xc:"#89b4fa" progress_fill.png
```

Or use GIMP:
1. New Image → 300x6 pixels
2. Fill with color (#313244 for bg, #89b4fa for fill)
3. Export as PNG

---

## Installation Instructions

### 1. Copy Files to Plymouth Directory

```bash
# Copy theme to Plymouth
sudo mkdir -p /usr/share/plymouth/themes/wehttamsnaps-spinner
sudo cp plymouth/wehttamsnaps-spinner/* /usr/share/plymouth/themes/wehttamsnaps-spinner/

# Set permissions
sudo chmod 644 /usr/share/plymouth/themes/wehttamsnaps-spinner/*
```

### 2. Set as Default Theme

```bash
# List available themes
plymouth-set-default-theme -l

# Set WehttamSnaps theme
sudo plymouth-set-default-theme -R wehttamsnaps-spinner

# This rebuilds initramfs automatically with -R flag
```

### 3. Verify Installation

```bash
# Check current theme
plymouth-set-default-theme

# Should output: wehttamsnaps-spinner
```

### 4. Test Theme (Optional)

```bash
# Test in TTY (Ctrl+Alt+F2)
sudo plymouthd
sudo plymouth --show-splash

# Wait 10 seconds, then quit
sudo plymouth --quit
```

---

## Troubleshooting

### Theme doesn't appear on boot

```bash
# Rebuild initramfs manually
sudo mkinitcpio -P

# Check for errors
journalctl -b | grep plymouth
```

### Logo not centered or wrong size

Edit `wehttamsnaps-spinner.script`:
```javascript
// Adjust scale factor (line ~27)
logo_scale = 150.0 / logo_height;  // Make smaller (150 instead of 200)

// Adjust Y position (line ~33)
logo_sprite.SetY((screen_height - logo_image.GetHeight()) / 2 - 100);  // Move up
```

### Rotation too fast/slow

Edit `wehttamsnaps-spinner.script`:
```javascript
// Adjust rotation speed (line ~41)
global.angle = global.angle + 0.03;  // Slower (0.03 instead of 0.05)
global.angle = global.angle + 0.08;  // Faster (0.08 instead of 0.05)
```

### Colors don't match

Edit `wehttamsnaps-spinner.script`:
```javascript
// Background color (lines 18-19)
Window.SetBackgroundTopColor(0.11, 0.11, 0.18);  // RGB values 0-1

// Progress bar color
# Recreate progress_fill.png with desired color
convert -size 300x6 xc:"#YOUR_COLOR" progress_fill.png
```

---

## Customization Tips

### Change Boot Messages

Edit `wehttamsnaps-spinner.script` (lines ~113-119):
```javascript
startup_messages = [
  "Your custom message 1",
  "Your custom message 2",
  "Your custom message 3",
  "Your custom message 4",
  "Your custom message 5"
];
```

### Add More Effects

**Fade-in effect:**
```javascript
// Add to rotate_logo() function
opacity = Math.min(global.angle / 3.14159, 1.0);
logo_sprite.SetOpacity(opacity);
```

**Pulsing effect:**
```javascript
// Add to rotate_logo() function
scale = 1.0 + Math.sin(global.angle) * 0.1;
scaled = logo_image.Scale(logo_width * logo_scale * scale, logo_height * logo_scale * scale);
logo_sprite.SetImage(scaled);
```

---

## Alternative: Simple Static Logo Theme

If spinning doesn't work well, create a simpler static theme:

```javascript
// Replace rotate_logo() with:
fun fade_logo() {
  // Simple fade-in effect
  if (global.angle < 1.0) {
    global.angle = global.angle + 0.02;
    logo_sprite.SetOpacity(global.angle);
  }
}

Plymouth.SetRefreshFunction(fade_logo);
```

---

## Uninstall Theme

```bash
# Switch back to default
sudo plymouth-set-default-theme -R bgrt

# Remove theme files
sudo rm -rf /usr/share/plymouth/themes/wehttamsnaps-spinner
```

---

## Quick Install Script

Create `install-plymouth.sh`:

```bash
#!/bin/bash
# Install WehttamSnaps Plymouth Theme

set -e

echo "Installing WehttamSnaps Plymouth theme..."

# Copy files
sudo mkdir -p /usr/share/plymouth/themes/wehttamsnaps-spinner
sudo cp plymouth/wehttamsnaps-spinner/* /usr/share/plymouth/themes/wehttamsnaps-spinner/
sudo chmod 644 /usr/share/plymouth/themes/wehttamsnaps-spinner/*

# Set as default and rebuild initramfs
sudo plymouth-set-default-theme -R wehttamsnaps-spinner

echo "✓ Plymouth theme installed!"
echo "Reboot to see the new boot splash."
```

Make executable: `chmod +x install-plymouth.sh`

---

## Colors Used

- **Background:** `#1e1e2e` (Catppuccin Mocha)
- **Brand Text:** White `#ffffff`
- **Tagline:** Blue `#89b4fa` (WehttamSnaps accent)
- **Progress Bar BG:** `#313244` (Dark gray)
- **Progress Bar Fill:** `#89b4fa` (Blue)

---

## Requirements

- Plymouth (installed by default on most distros)
- PNG images (logo, progress bars)
- Arch Linux with systemd boot

---

## Resources

- [Plymouth Scripting Guide](https://www.freedesktop.org/wiki/Software/Plymouth/Scripts/)
- [Plymouth Themes Repository](https://github.com/adi1090x/plymouth-themes)
- Logo creation: GIMP, Inkscape, or your existing camera aperture image

---

**Made with ❤️ for WehttamSnaps**  
Photography • Gaming • Content Creation
