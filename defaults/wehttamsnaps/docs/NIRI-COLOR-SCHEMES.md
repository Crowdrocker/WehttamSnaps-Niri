# Niri Color Schemes & Gradients Guide

Beautiful gradient borders and focus rings for your WehttamSnaps setup.

---

## 🎨 Current Color Scheme

**WehttamSnaps Photography** (Blue/Purple gradient)

```kdl
layout {
    focus-ring {
        width 3
        active-gradient from="#89b4fa" to="#b4c8fa" angle=45 relative-to="workspace-view"
        inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
    }
    
    border {
        width 2
        active-gradient from="#89b4fa" to="#cba6f7" angle=45 relative-to="workspace-view"
        inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
    }
}
```

**Colors:**
- Active: Blue (#89b4fa) → Purple (#cba6f7)
- Inactive: Dark Gray (#313244) → Mid Gray (#45475a)
- Angle: 45° diagonal

---

## 🌈 Pre-Made Color Schemes

Copy these into `~/.config/niri/conf.d/00-base.kdl` to change your look!

### 1. Photography Sunset (Orange/Pink)

```kdl
border {
    width 2
    active-gradient from="#fab387" to="#f38ba8" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#fab387" to="#f9e2af" angle=45 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
}
```

### 2. Gaming Neon (Cyan/Green)

```kdl
border {
    width 2
    active-gradient from="#94e2d5" to="#a6e3a1" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#89dceb" to="#94e2d5" angle=45 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
}
```

### 3. Minimalist (White/Gray)

```kdl
border {
    width 2
    active-gradient from="#cdd6f4" to="#bac2de" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#f5e0dc" to="#cdd6f4" angle=45 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
}
```

### 4. Cyberpunk (Pink/Purple)

```kdl
border {
    width 2
    active-gradient from="#f5c2e7" to="#cba6f7" angle=90 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=90 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#f38ba8" to="#f5c2e7" angle=90 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=90 relative-to="workspace-view"
}
```

### 5. Terminal Hacker (Green/Lime)

```kdl
border {
    width 2
    active-gradient from="#a6e3a1" to="#94e2d5" angle=135 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=135 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#a6e3a1" to="#f9e2af" angle=135 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=135 relative-to="workspace-view"
}
```

### 6. Fire (Red/Orange)

```kdl
border {
    width 2
    active-gradient from="#f38ba8" to="#fab387" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#eba0ac" to="#f38ba8" angle=45 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
}
```

### 7. Ocean (Blue/Teal)

```kdl
border {
    width 2
    active-gradient from="#89b4fa" to="#89dceb" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#74c7ec" to="#89dceb" angle=45 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
}
```

### 8. Forest (Green/Yellow)

```kdl
border {
    width 2
    active-gradient from="#a6e3a1" to="#f9e2af" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#a6e3a1" to="#94e2d5" angle=45 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
}
```

### 9. Monochrome (Black/White)

```kdl
border {
    width 2
    active-gradient from="#f5e0dc" to="#ffffff" angle=45 relative-to="workspace-view"
    inactive-gradient from="#11111b" to="#313244" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#cdd6f4" to="#f5e0dc" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}
```

### 10. Rainbow (Multi-color)

```kdl
border {
    width 2
    active-gradient from="#f38ba8" to="#89b4fa" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}

focus-ring {
    width 3
    active-gradient from="#f9e2af" to="#a6e3a1" angle=45 relative-to="workspace-view"
    inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
}
```

---

## 🎨 Catppuccin Mocha Color Palette

All colors above are from Catppuccin Mocha theme:

| Color | Hex | Use |
|-------|-----|-----|
| Rosewater | `#f5e0dc` | Subtle accents |
| Flamingo | `#f2cdcd` | Soft pink |
| Pink | `#f5c2e7` | Bright pink |
| Mauve | `#cba6f7` | Purple |
| Red | `#f38ba8` | Error, alerts |
| Maroon | `#eba0ac` | Dark red |
| Peach | `#fab387` | Orange |
| Yellow | `#f9e2af` | Warnings |
| Green | `#a6e3a1` | Success |
| Teal | `#94e2d5` | Cyan-green |
| Sky | `#89dceb` | Light cyan |
| Sapphire | `#74c7ec` | Bright blue |
| Blue | `#89b4fa` | Primary accent |
| Lavender | `#b4befe` | Light purple |
| Text | `#cdd6f4` | Primary text |
| Subtext1 | `#bac2de` | Secondary text |
| Subtext0 | `#a6adc8` | Tertiary text |
| Overlay2 | `#9399b2` | Overlays |
| Overlay1 | `#7f849c` | Overlays |
| Overlay0 | `#6c7086` | Overlays |
| Surface2 | `#585b70` | Surface |
| Surface1 | `#45475a` | Surface |
| Surface0 | `#313244` | Surface |
| Base | `#1e1e2e` | Background |
| Mantle | `#181825` | Dark background |
| Crust | `#11111b` | Darkest |

---

## 🔧 Customization Options

### Gradient Angle

```kdl
angle=0    // Horizontal (left to right)
angle=45   // Diagonal (bottom-left to top-right)
angle=90   // Vertical (bottom to top)
angle=135  // Diagonal (bottom-right to top-left)
angle=180  // Horizontal (right to left)
angle=270  // Vertical (top to bottom)
```

**Visual:**
```
0°    →→→
45°   ↗↗↗
90°   ↑↑↑
135°  ↖↖↖
180°  ←←←
270°  ↓↓↓
```

### Border Width

```kdl
width 1   // Thin (subtle)
width 2   // Normal (default)
width 3   // Thick (prominent)
width 4   // Very thick (gaming style)
```

### Relative-To Options

```kdl
relative-to="workspace-view"  // Gradient relative to workspace (recommended)
relative-to="window"          // Gradient relative to each window
```

**Difference:**
- `workspace-view` - Gradient stays fixed on workspace, looks consistent
- `window` - Each window has its own gradient, more dynamic

---

## 🎯 How to Change Colors

### 1. Edit Config

```bash
kate ~/.config/niri/conf.d/00-base.kdl
```

### 2. Find Layout Section

Search for `layout {`

### 3. Replace Border/Focus-Ring

Copy one of the schemes above and paste it in.

### 4. Reload Niri

```bash
niri msg action reload-config
# or: Mod + Shift + Ctrl + R
```

### 5. See Changes Instantly

Your borders and focus rings update immediately!

---

## 🎨 Create Custom Gradients

### Step 1: Pick Your Colors

Use a color picker:
- https://catppuccin.com/palette
- https://coolors.co
- Or any hex color picker

### Step 2: Choose 2 Colors

For active border:
- **From:** Start color (e.g., `#89b4fa`)
- **To:** End color (e.g., `#cba6f7`)

### Step 3: Apply

```kdl
border {
    width 2
    active-gradient from="#YOUR_COLOR_1" to="#YOUR_COLOR_2" angle=45 relative-to="workspace-view"
    inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
}
```

### Step 4: Test Angles

Try different angles (0, 45, 90, 135) to see what looks best!

---

## 💡 Design Tips

### 1. Contrast

Active borders should stand out from inactive:
- ✅ Bright active, dark inactive
- ❌ Similar brightness for both

### 2. Complementary Colors

Use colors that work together:
- Blue → Purple (cool)
- Orange → Pink (warm)
- Green → Yellow (natural)

### 3. Brand Colors

Match your WehttamSnaps branding:
- Photography: Blue/Purple/Pink
- Nature: Green/Teal
- Urban: Gray/White/Blue

### 4. Mood

Choose colors for different moods:
- **Work:** Blue/Teal (calm, focused)
- **Gaming:** Green/Cyan (energetic)
- **Creative:** Pink/Purple (artistic)
- **Coding:** Green/Yellow (terminal vibes)

### 5. Angle Direction

- **45° / 135°** - Dynamic, modern
- **90° / 270°** - Clean, organized
- **0° / 180°** - Classic, traditional

---

## 🔄 Per-Workspace Colors (Advanced)

Want different colors per workspace? Add to `30-workspaces.kdl`:

```kdl
workspace "3" {
    name "Photo"
    icon "📷"
    
    // Override layout colors for this workspace
    layout {
        border {
            active-gradient from="#f38ba8" to="#fab387" angle=45 relative-to="workspace-view"
        }
    }
}
```

**Example uses:**
- Workspace 3 (Photo): Warm sunset gradient
- Workspace 9 (Gaming): Neon green gradient
- Workspace 2 (Terminal): Hacker green gradient

---

## 🎮 Gaming Mode Colors

When gaming mode is active, use high-contrast colors:

```kdl
// Add to toggle-gamemode.sh script
# When enabling gaming mode, temporarily use bright gradients
# When disabling, restore normal colors
```

Or manually switch to "Gaming Neon" scheme when gaming!

---

## 📸 Screenshot Your Setup

Show off your gradients:

```bash
# Full screen
grim ~/Pictures/niri-gradient-$(date +%Y%m%d-%H%M%S).png

# Active window
Mod + Print
```

Share on r/unixporn! 🎨

---

## 🔗 Resources

- **Niri Wiki:** https://github.com/YaLTeR/niri/wiki/Configuration:-Layout
- **Catppuccin:** https://catppuccin.com/palette
- **Color Tool:** https://coolors.co
- **Gradient Generator:** https://cssgradient.io/

---

## 🎯 Quick Reference

### Copy-Paste Template

```kdl
layout {
    border {
        width 2
        active-gradient from="#COLOR1" to="#COLOR2" angle=45 relative-to="workspace-view"
        inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
    }
    
    focus-ring {
        width 3
        active-gradient from="#COLOR1" to="#COLOR3" angle=45 relative-to="workspace-view"
        inactive-gradient from="#45475a" to="#585b70" angle=45 relative-to="workspace-view"
    }
}
```

### Replace:
- `#COLOR1` - Your primary brand color
- `#COLOR2` - Your secondary brand color  
- `#COLOR3` - Lighter variant of COLOR1

---

## 💾 Save Your Favorite Schemes

Create a file: `~/.config/wehttamsnaps/color-schemes.kdl`

Save all your favorite gradients there for easy switching!

```kdl
// WehttamSnaps Photography Blue
// Copy to 00-base.kdl when needed
layout {
    border {
        width 2
        active-gradient from="#89b4fa" to="#cba6f7" angle=45 relative-to="workspace-view"
        inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
    }
}

// WehttamSnaps Sunset
// Copy to 00-base.kdl when needed
layout {
    border {
        width 2
        active-gradient from="#fab387" to="#f38ba8" angle=45 relative-to="workspace-view"
        inactive-gradient from="#313244" to="#45475a" angle=45 relative-to="workspace-view"
    }
}
```

---

## 🎨 Your Current Setup

**Scheme:** WehttamSnaps Photography (Blue/Purple)  
**Active:** `#89b4fa` → `#cba6f7`  
**Angle:** 45°  
**Width:** 2px  

Perfect for photography and content creation! 📷

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation

**Make your borders beautiful! 🌈**
