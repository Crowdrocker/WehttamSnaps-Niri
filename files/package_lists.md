# WehttamSnaps Package Lists

Organized package lists for easy installation.

---

## 📦 core.list - Essential Packages (Required)

```
# === COMPOSITOR & WINDOW MANAGER ===
niri
quickshell
noctalia-shell

# === TERMINAL ===
ghostty
foot

# === DISPLAY SERVER ===
xorg-xwayland
xdg-desktop-portal
xdg-desktop-portal-gtk

# === AUDIO ===
pipewire
wireplumber
pipewire-alsa
pipewire-jack
pipewire-pulse
pavucontrol
qpwgraph

# === BASIC UTILITIES ===
git
git-lfs
brightnessctl
playerctl
cliphist
grim
slurp
swappy
wl-clipboard

# === FILE MANAGER ===
thunar
thunar-archive-plugin
thunar-volman
tumbler
ffmpegthumbnailer

# === BROWSER ===
brave-bin

# === TEXT EDITOR ===
kate
neovim

# === SYSTEM TOOLS ===
fastfetch
starship
btop
polkit
hyprpolkitagent

# === FONTS ===
ttf-fira-code
ttf-jetbrains-mono-nerd
ttf-roboto
noto-fonts
noto-fonts-emoji
noto-fonts-cjk

# === THEMING ===
matugen-git
qt6ct
kvantum
gtk3
gtk4

# === BASE SYSTEM ===
base
base-devel
linux
linux-firmware
linux-headers
intel-ucode
amd-ucode

# === BOOTLOADER ===
grub
efibootmgr
os-prober

# === NETWORKING ===
networkmanager
nm-connection-editor
network-manager-applet
iwd
dhcpcd
```

**Install command:**
```bash
paru -S --needed - < ~/.config/wehttamsnaps/packages/core.list
```

---

## 📷 photography.list - Photography & Creative Tools

```
# === RAW PROCESSING ===
darktable
rawtherapee

# === PHOTO EDITING ===
gimp
krita

# === PHOTO MANAGEMENT ===
digikam
shotwell

# === VECTOR GRAPHICS ===
inkscape

# === 3D MODELING ===
blender

# === IMAGE VIEWERS ===
gwenview
nomacs
qview
loupe

# === COLOR MANAGEMENT ===
colord
argyllcms

# === WACOM TABLET (if you use one) ===
# xf86-input-wacom
# libwacom

# === GIMP PLUGINS ===
gimp-help-en
gimp-plugin-gmic

# === INKSCAPE EXTRAS ===
inkscape-docs
```

**Install command:**
```bash
paru -S --needed - < ~/.config/wehttamsnaps/packages/photography.list
```

---

## 🎮 gaming.list - Gaming Packages

```
# === STEAM ===
steam
steam-native-runtime

# === PROTON & COMPATIBILITY ===
proton-ge-custom-bin
protonup-qt
wine-staging
wine-mono
wine-gecko
winetricks

# === GAME LAUNCHERS ===
lutris
heroic-games-launcher-bin

# === PERFORMANCE ===
gamemode
lib32-gamemode
gamescope
mangohud
lib32-mangohud
goverlay

# === GPU DRIVERS (AMD RX 580) ===
mesa
lib32-mesa
vulkan-radeon
lib32-vulkan-radeon
vulkan-icd-loader
lib32-vulkan-icd-loader
vulkan-mesa-layers
lib32-vulkan-mesa-layers
mesa-utils
vulkan-tools

# === ADDITIONAL LIBRARIES ===
lib32-pipewire
lib32-pipewire-jack
vkd3d
lib32-vkd3d
dxvk-bin
lib32-nvidia-utils

# === INPUT ===
antimicrox
sc-controller

# === MOD MANAGERS ===
# Run via Wine/Lutris:
# - Vortex
# - Mod Organizer 2
# - Wabbajack
```

**Install command:**
```bash
paru -S --needed - < ~/.config/wehttamsnaps/packages/gaming.list
```

---

## 🎥 streaming.list - Streaming & Recording

```
# === OBS STUDIO ===
obs-studio
obs-vaapi
obs-vkcapture

# === SCREEN RECORDING ===
wf-recorder
gpu-screen-recorder

# === AUDIO PROCESSING ===
easyeffects
calf
lsp-plugins

# === STREAMING TOOLS ===
v4l2loopback-dkms

# === CHAT OVERLAYS ===
# Run as webapps or:
webcord-bin
discord
telegram-desktop
```

**Install command:**
```bash
paru -S --needed - < ~/.config/wehttamsnaps/packages/streaming.list
```

---

## 🛠️ optional.list - Nice-to-Have Packages

```
# === ADDITIONAL TERMINALS ===
kitty
alacritty

# === ADDITIONAL EDITORS ===
code
micro

# === FILE MANAGERS ===
dolphin
nautilus
ranger
nnn
yazi

# === BROWSERS ===
firefox
chromium
zen-browser-bin

# === MEDIA PLAYERS ===
mpv
mpv-mpris
vlc
celluloid

# === MUSIC ===
spotify-launcher
cmus
ncmpcpp
mpd

# === ARCHIVE TOOLS ===
ark
file-roller
p7zip
unrar
unzip
zip

# === PDF VIEWERS ===
zathura
zathura-pdf-mupdf
okular
evince

# === OFFICE ===
libreoffice-fresh

# === EMAIL ===
thunderbird

# === SYSTEM MONITORS ===
gnome-system-monitor
mission-center

# === DISK UTILITIES ===
gparted
gnome-disk-utility
btrfs-assistant

# === DEVELOPMENT ===
github-desktop-plus-bin
docker
docker-compose

# === VIRTUALIZATION ===
# virt-manager
# qemu-full
# libvirt

# === SECURITY ===
keepassxc

# === NETWORKING TOOLS ===
wireshark-qt
nmap

# === DOWNLOAD MANAGERS ===
qbittorrent
yt-dlp

# === PRODUCTIVITY ===
obsidian
notion-app-enhanced

# === SCREENSHOT TOOLS ===
flameshot

# === WALLPAPER TOOLS ===
azote
waypaper
swww
hyprpaper

# === FUN ===
cmatrix
lolcat
cowsay
fortune-mod
sl

# === PLYMOUTH THEMES ===
plymouth
plymouth-theme-arch-charge
```

**Install command:**
```bash
paru -S --needed - < ~/.config/wehttamsnaps/packages/optional.list
```

---

## 🔧 development.list - Development Tools

```
# === LANGUAGES ===
python
python-pip
nodejs
npm
rust
go

# === BUILD TOOLS ===
cmake
make
gcc
clang

# === VERSION CONTROL ===
git
git-lfs
lazygit

# === EDITORS / IDEs ===
code
neovim
vim

# === CONTAINERS ===
docker
docker-compose
podman

# === DATABASES ===
postgresql
mariadb

# === DEBUGGING ===
gdb
valgrind
strace

# === PYTHON TOOLS ===
python-virtualenv
python-pipenv
python-poetry

# === NODE TOOLS ===
yarn
pnpm
```

**Install command:**
```bash
paru -S --needed - < ~/.config/wehttamsnaps/packages/development.list
```

---

## 📦 Installation Guide

### Install All Essential Packages

```bash
cd ~/.config/wehttamsnaps/packages

# Core (required)
paru -S --needed $(cat core.list | grep -v '^#' | grep -v '^$')

# Photography (recommended)
paru -S --needed $(cat photography.list | grep -v '^#' | grep -v '^$')

# Gaming (recommended)
paru -S --needed $(cat gaming.list | grep -v '^#' | grep -v '^$')

# Streaming (optional)
paru -S --needed $(cat streaming.list | grep -v '^#' | grep -v '^$')

# Optional (as needed)
paru -S --needed $(cat optional.list | grep -v '^#' | grep -v '^$')
```

### Install Specific Categories

```bash
# Just photography tools
cat photography.list | grep -v '^#' | xargs paru -S --needed

# Just gaming
cat gaming.list | grep -v '^#' | xargs paru -S --needed
```

### Update All Packages

```bash
paru -Syu
# or use alias:
update-all
```

---

## 💾 Package Count Summary

- **core.list**: ~60 packages (Essential)
- **photography.list**: ~15 packages (Creative work)
- **gaming.list**: ~35 packages (Gaming optimized)
- **streaming.list**: ~12 packages (OBS/streaming)
- **optional.list**: ~70 packages (Nice-to-have)
- **development.list**: ~30 packages (Dev tools)

**Total:** ~220 packages (vs your original 600+)

---

## 🔄 Maintenance

### Check for Orphaned Packages

```bash
paru -Qtdq
# Remove orphans:
clean-orphans
```

### List Explicitly Installed

```bash
paru -Qe
```

### Find Large Packages

```bash
paru -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4$5, name}' | sort -h | tail -20
```

---

## 📝 Notes

- **AUR packages** (like `brave-bin`, `proton-ge-custom-bin`) may take longer to install
- **GPU drivers** are AMD RX 580 specific - adjust if using different GPU
- **Development tools** are optional unless you code
- **Virtualization** tools commented out - uncomment if needed

---

**Made for WehttamSnaps** | Photography • Gaming • Content Creation
