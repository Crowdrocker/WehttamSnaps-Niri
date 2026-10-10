# Void capability matrix

This is the delivery ledger for user-selectable iNiR capabilities on Void.
The contract terms are defined by ADR-0004. A row reaches **supported** only
after provider, provisioning, activation, operation, and verification pass.

| Capability | Profile | Void provider | Activation | Current state |
|---|---|---|---|---|
| Niri + Quickshell | base | XBPS `niri`, `quickshell`, Qt 6 packages | session supervisor | VM validated |
| Session D-Bus and login | base | XBPS `dbus`, `elogind`, `turnstile` | confirmed runit services + turnstile | VM validated |
| Graphical login | base | XBPS `sddm`, `xorg-minimal` + packaged Niri desktop entry | confirmed SDDM runit service | VM validated: ii-pixel greeter persisted across reboot; validation autologin proved SDDM launches `niri --session` into a seat0 Wayland session with one Quickshell instance; Doctor 27/27; autologin removed and final boot returned to greeter |
| iNiR lifecycle | base | installed launcher | systemd, turnstile, or runsvdir by predicate | VM validated |
| Network | base | XBPS `NetworkManager` | runit service with interactive migration from Void's base dhcpcd/wpa_supplicant stack | VM + physical hardware validated: after the migration and a real reboot, `nmcli` reported connected Wi-Fi, `runsv NetworkManager` directly supervised the daemon, persistent runit links resolved to `/etc/sv/NetworkManager`, competing `dhcpcd`/standalone `wpa_supplicant`/`wicd` links were absent, and Doctor reported the Void NetworkManager provider running |
| Bluetooth | toolkit | XBPS `bluez`, `blueman`; audio adds `libspa-bluetooth` | confirmed `bluetoothd` runit service | VM validated for packages/service/D-Bus/group; physical hardware validation also detected the laptop controller, powered it on and exposed the expected audio profiles. Pairing to an external device is not a release gate and was not separately exercised |
| Awww wallpaper | base | official XBPS `awww` | systemd transient unit or session daemon by predicate | VM validated: daemon + query + img apply on wayland-1 |
| Interactive Web Wallpaper | base | XBPS `qt6-webengine`, `layer-shell-qt`; Qt QML runner (`qml6`/`qml`, Void fallback `/usr/lib/qt6/bin/qml`) | per-screen child process | VM validated on the clean 2.31 release image: pure-Qt host probe and live WebEngine render pass; Doctor repair and local guards pass |
| GameMode | base | built into iNiR | session process | VM validated: manual toggle through the real `globalActions` IPC changed `inactive (off)` -> `active (manual)` -> `inactive (off)`; `discover-overlay` stayed absent; notification suppression is enabled in the effective config/wiring. `disableNiriAnimations` is intentionally false in the current default/effective profile, so changing Niri animation state is not claimed |
| Screenshots | screencapture | XBPS `grim`, `slurp`, `swappy`, `wl-clipboard`, `jq` | direct session processes | VM validated: clipboard fallback roundtrip (`wl-paste`); capture binaries present |
| Screen recording | screencapture | XBPS `wf-recorder`, `ffmpeg`; audio profile provides `pipewire` | direct session processes | VM validated: `pipewire`/`wireplumber`/`pipewire-pulse` user services run; `pactl` reports PulseAudio on PipeWire 1.6.7 |
| Clipboard history and paste | base/toolkit | XBPS `wl-clipboard`, `cliphist`; verified upstream `ydotool` v1.0.4 source | session watchers + predicate-selected ydotool user service | ydotool provider VM validated: provision, permissions, service, socket, direct injection, idempotency, and lock-screen keyboard UI; Superpaste not separately exercised |
| Cloudflare WARP | toolkit | verified upstream `cloudflare-warp` v2026.7.1377.0, extracted without Debian scripts | iNiR-owned `warp-svc` runit service + `vlogger` subservice | VM validated: provision, daemon up, socket, version, runit logging, idempotency; pending: account registration, connection, and trace verification |
| Mission Center | toolkit | Flatpak `io.missioncenter.MissionCenter` from Flathub | Flatpak application + `~/.local/bin/missioncenter` wrapper | VM validated: install, launcher, selective repair, and idempotency |
| OCR | toolkit/screencapture | XBPS Tesseract language packages + pinned `tessdata_fast` vertical models | direct process + `tesseract` adapter | VM validated: required horizontal packages, verified vertical models, model-load smoke tests, repair, and idempotency |
| Themes, icons, cursors | fonts/theme | pinned adw-gtk3 6.5, WhiteSur 2026-09-10, Capitaine r5 | files/config only | VM validated: expected GTK/icon/cursor names, Adwaita fallback, and idempotency |
| Required UI fonts | fonts/theme | XBPS `nerd-fonts-ttf`, `noto-fonts-emoji`, `fontconfig` + pinned Material Symbols Rounded, Roboto Flex 3.200, Gabarito, Oxanium, and Rubik | Fontconfig cache + Void-only alias for Google Sans Flex | VM validated: exact family resolution, checksums, selective repair, and idempotency |
| Darkly Qt style/settings | fonts/theme | pinned Darkly v0.5.39 source + Void Qt6/KF6 build dependencies including `kf6-kdecoration-devel` | Qt6 KStyle + KDecoration settings KCM | VM validated: reproduced the style-only partial install, rebuilt with decorations enabled, installed `darkly6.so`, `org.kde.darkly.so` and `kcm_darklydecoration.so`, verified runtime linkage and `darkly-settings6`, then passed provider idempotency |
| Foot terminal theming | fonts/theme | XBPS `foot` + generated `~/.config/foot/inir-colors.ini` | file generation + Foot reload | VM validated with `foot-1.28.0_1`: legacy `colors.ini` include migrated to the managed name, the generated file exists, and `foot --check-config` passes; static coverage keeps shipped config/generator/installer/uninstall aligned |
| Shell desktop parity | base/fonts/theme | XBPS `plasma-integration`, `kf6-syntax-highlighting`, iNiR Turnstile env handoff, Void distro asset | Niri + Quickshell user session | VM validated: valid KDL, KDE platform integration, sidebars, Void icon asset/mapping, refreshed `NIRI_SOCKET`, and end-to-end `Mod+Q` input path; rendered-icon visual confirmation is not separately recorded |
| Package updates/search/catalog | base | XBPS | direct terminal commands; install/remove request sudo elevation | VM validated: update count, repository/installed search, 34 catalog targets, QML backend/target resolution, UI install/remove command wiring, and a real isolated-root XBPS install/remove transaction; system-root password entry was not automated because `sudo -n` is unavailable in the VM |
| Power profiles | base | XBPS `power-profiles-daemon` | confirmed-elevation runit service | VM validated: package/provider, confirmed privileged runit activation, persistence after reboot, `powerprofilesctl list`, D-Bus ownership, repair mapping, service file, and polkit policy pass |
| Doctor and ABI repair | base | XBPS diagnostics | direct commands | VM validated: Void package repair mappings, Quickshell/Qt ABI no-op, package-manager/versioning metadata, and non-systemd predicate paths pass the Void closure checker |
| Legacy Super-tap opt-in | optional/legacy | XBPS `python3-evdev` + installed helper | systemd, Turnstile, or runsvdir by predicate | VM validated: `II_ENABLE_SUPER_DAEMON=1` creates and runs the Turnstile service; a normal reinstall removes the managed service/helper and leaves the default off |

## Rules

- Profiles exposed by the Void installer match the Arch installer model.
- Missing optional profiles do not block the base shell, but selecting a
  profile must install all providers required by that profile.
- WARP never starts a privileged service or creates an account from QML. It
  reports the stopped daemon and requires explicit operator registration.
- Packaging iNiR itself as an XBPS package remains outside V1. This matrix
  covers the per-user installer.
- Exact package names and upstream versions move from **TBD** only after they
  are validated in the Void VM.
