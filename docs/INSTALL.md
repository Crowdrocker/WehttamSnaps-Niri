# Installation

The normal `./setup install` flow is supported on Arch-based systems and on
**Void Linux glibc + runit**. Void uses XBPS for packaged
dependencies and explicit providers for the small set of capabilities that are
not available as suitable Void packages.

> **Void scope:** glibc + elogind + runit/Turnstile is the validated profile.
> Void musl and a seatd-only session are compatibility profiles, not release
> targets. See [iNiR on Void Linux](VOID.md).
>
> **NixOS:** there is an experimental flake path. See [NixOS](NIXOS.md).

---

## The Easy Way (Arch)

```bash
git clone https://github.com/snowarch/inir.git
cd inir
./setup install
```

Add `-y` if you don't want to answer questions:

```bash
./setup install -y
```

When it's done, **restart the computer**. Not log out, restart: the new groups, the login screen and
Niri's environment only apply after a reboot. Then pick Niri at the login screen.

**Black screen instead of the login screen?** On laptops with an NVIDIA GPU next to the integrated one,
SDDM's default X11 greeter can start on the GPU that has no screens. Setup already picks the Wayland login
screen for those machines; to switch by hand, open `./setup` → Extras → Install ii-pixel-sddm and choose
**Wayland with Niri**. If you already use another login screen (GDM, Plasma Login...), iNiR keeps it: a
first install asks once, and updates or running install again never switch it. To move to SDDM later, use
`./setup` → Extras → Install ii-pixel-sddm.

```bash
systemctl reboot
```

## The Easy Way (Void Linux)

Use the normal iNiR checkout and run `./setup install`. Void uses the same
installer entry point as the other supported distributions.

The first Void run is intentionally guided. The TUI shows a system snapshot,
the installation plan, backup location and progress stages before changing the
machine. It then:

- installs the selected dependency profiles with XBPS;
- checks free space before large XBPS transactions (notably the font profile);
- installs pinned/verified providers only where Void has no suitable package;
- configures the runit/Turnstile user-session path instead of assuming
  `systemd --user`;
- provisions PipeWire/WirePlumber, BlueZ, Power Profiles and other selected
  services through their Void providers;
- offers a rollback-safe NetworkManager handoff if Void is still using
  `dhcpcd`/standalone `wpa_supplicant`;
- offers SDDM only after the rest of the install is complete, using Void's
  packaged `niri --session` desktop entry.

The base Void installation must already have working hardware support for the
machine (kernel/firmware plus a usable Mesa/Vulkan or vendor graphics stack).
iNiR owns the rice and its userland providers; it does not guess GPU drivers,
rewrite the bootloader or choose hardware-specific kernel parameters.

Before provisioning Void dependencies, the installer runs a small graphics
preflight. It requires an accessible DRM render node and, for VirtIO guests,
rejects a negotiated feature set without `VIRTIO_GPU_F_VIRGL`. The release VM
uses VirGL (`virtio-vga-gl`/`virtio-gpu-gl`); the earlier plain VirtIO setup
fell back to software EGL and Niri did not expose a usable output. The check can
be bypassed explicitly with `INIR_SKIP_GRAPHICS_PREFLIGHT=1` for unsupported
experiments, but iNiR still does not install or choose GPU drivers.

Disk usage depends on what is already installed. In release testing a 20 GiB
Void root ran out of space during the large Nerd Fonts transaction, while the
30 GiB release VM completed the full profile and later had roughly 7 GiB free.
The installer now calculates the missing XBPS transaction and reserves extra
download/build headroom before starting it.

The NetworkManager and SDDM prompts can briefly change connectivity/login
ownership, so the non-interactive `./setup install -y` path leaves those two
decisions unchanged. For a new Void desktop, use the interactive run once.

After a graphical login through SDDM, iNiR should be supervised through the
selected non-systemd user-session tier. `niri --session` from a local TTY is the
documented recovery/debug path, not the normal installed startup flow.

Useful checks after installation:

```bash
inir doctor
inir status
inir logs --issues
```

Package search/update surfaces use XBPS on Void. See [Packages](PACKAGES.md),
[Void capabilities](VOID_CAPABILITIES.md) and the detailed [Void guide](VOID.md).

---

## The Hard Way (Manual)

For unsupported distributions, custom packaging, or when you intentionally do
not want the automated setup path.

### 1. Get dependencies

The bare minimum to not crash immediately:

| Package | Why |
|---------|-----|
| `niri` | The compositor. Obviously. |
| `quickshell` | The shell runtime (official repos). Chosen intentionally for faster and more reliable installs. |
| `syntax-highlighting` | Provides QML module `org.kde.syntaxhighlighting` (required by AiChat code blocks). |
| `kirigami` | KDE QML components used by shell modules. |
| `kdialog` | KDE runtime helper used by some dialogs/integrations. |
| `wl-clipboard` | Copy/paste. |
| `cliphist` | Clipboard history. |
| `pipewire` + `wireplumber` | Audio. |
| `grim` + `slurp` | Screenshots. |
| `materialyoucolor` | Material You colors from wallpaper (Python, installed via venv). |
| `plasma-browser-integration` | Browser MPRIS sessions, controls, and artwork. |
| `plasma-integration` | KDE platform theme plugin (reads kdeglobals for Qt app colors). |
| `darkly-bin` (AUR) | Darkly Qt style (Material You widget rendering). |

For everything else, check [PACKAGES.md](PACKAGES.md). It's organized by category so you can skip what you don't need.

The package names in this manual table are Arch-oriented. On Void, use the
automated XBPS/provider path above rather than translating this table by hand;
for example, Darkly is built from pinned source with the KF6 KDecoration
development package so its settings KCM is available too.

> **Note on quickshell package:** iNiR intentionally uses `quickshell` from official repos to avoid long AUR compile times and update-time build failures.
>
> **Runtime extras used by features:**
> - `socat` for YTMusic IPC fallback control
> - `fprintd` for fingerprint lockscreen support
>
> **Optional content packs** (`./setup` → Extras): the iNiR-Walls wallpaper
> pack, the ii-pixel-sddm login theme, YAMIS icons, and the Kira mascot art
> pack. The mascot feature ships
> disabled and does nothing until you install the pack and enable her in
> Settings › Mascot.
>
> The art pack and the shell have separate jobs. `snowarch/inir-mascot`
> publishes the PNG/GIF files. iNiR ships the required
> `assets/images/mascot/manifest.json`, dialogue, pose pools, settings and
> runtime behavior. Updating or reinstalling the art pack does not replace the
> shell manifest; normal iNiR install/update paths provide it. Extras stages and
> verifies the complete archive before touching live assets, records the release
> tag plus an installed-tree hash, and repairs missing or corrupt files during a
> later `./setup update` without auto-installing the optional pack for new users.
> iNiR must never publish a shell manifest that depends on mascot art which has
> not been published by `snowarch/inir-mascot` yet. For Nix, bump the pinned
> mascot release only after that art release exists.
>
> **Important for minimal Arch installs:**
> If shell startup fails with `module "org.kde.syntaxhighlighting" is not installed`, install:
> `syntax-highlighting kirigami kdialog`

### 2. Clone the repo

```bash
git clone https://github.com/snowarch/inir.git ~/.config/quickshell/inir
```

### 3. Copy the configs

```bash
cp -r dots/.config/* ~/.config/
```

This gives you:
- Niri config wired to the `inir` launcher
- Theming templates for Material You colors
- GTK settings

### 4. Enable the iNiR user service

```bash
inir service install
inir service enable
inir service start
```

### 5. Restart Niri

```bash
niri msg action load-config-file
```

Or log out and back in.

---

## Did it work?

Check the logs:

```bash
inir logs
```

If everything went well, you should see:
- Bar at the top (the thing with the clock)
- Background/wallpaper (hopefully not a black screen)
- `Mod+Tab` opens the Niri overview (native)
- `Mod+Space` (`Super+Space`) toggles the ii overview
- `Alt+Tab` cycles windows using ii's switcher
- `Super+V` opens the clipboard panel
- `Super+Shift+S` takes a region screenshot

If something's broken, the logs will probably tell you which package is missing. Probably.

---

## What now?

- [KEYBINDS.md](KEYBINDS.md) - Learn the shortcuts
- [IPC.md](IPC.md) - Make your own keybindings
- [SETUP.md](SETUP.md) - Updating, uninstalling, how configs are handled
- [PACKAGES.md](PACKAGES.md) - Full package list if something's missing
