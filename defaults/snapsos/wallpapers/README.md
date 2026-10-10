# Wallpaper System

Wallpaper group switcher with DMS integration and per-group color settings.

## Usage

| Keybind | Action |
|---------|--------|
| SUPER+W | Open group selector |
| ALT+W | Next wallpaper |
| ALT+SHIFT+W | Previous wallpaper |

## Structure

Groups are folders in this directory. Each folder contains wallpapers and
optionally a `wallpaper.conf`:

```
my-group/
├── wallpaper.png
├── wallpaper2.jpg
└── wallpaper.conf
```

### wallpaper.conf

```
Theme_Category:dynamic    # generic / dynamic / custom / registry
Generic_Color:dynamic     # color name, dynamic, or custom
Matugen:vibrant           # palette variant
Mode:dark                 # dark or light
Preset:-                  # theme preset name
```

## Group behavior

- Images cycle in alphabetical order
- Single-image groups do not cycle
- Cycling is handled by DMS, not the script

## Command

```sh
wallpaper-select          # Opens FZF group picker
wallpaper-select default  # Sets the "default" group directly
```
