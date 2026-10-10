# Runtime and Boot Pipeline

What happens between "user logs in" and "shell is on screen", step by step.

## The full sequence

```
User logs in
  |
Display manager starts Niri through its managed session
  |
Niri publishes DISPLAY, WAYLAND_DISPLAY and NIRI_SOCKET to the user manager
  |
session supervisor starts iNiR
  |-- systemd user manager: niri.service READY -> inir.service
  `-- Void/runit: Turnstile envdir or guarded runsvdir -> ~/.config/service/inir
  |
ExecStart calls: /usr/bin/inir run --session
  |
inir script (bash):
  - Validates QS/Qt ABI compatibility
  - Sets QT_SCALE_FACTOR=1
  - Suppresses noisy Qt log categories
  - Inherits Niri's published session environment without guessing sockets
  - Launches: qs -c inir
  |
Quickshell loads shell.qml
  |
ShellRoot initialization:
  1. Force-instantiate startup-critical singletons (Idle, PowerProfilePersistence,
     DevNavigation, ShellEditSession, TrayService)
  2. Load FirstRunExperience (checks if first run)
  3. Load ConflictKiller (kills conflicting trays/notification daemons)
  4. Materialize shell-wide action/IPC owners that must exist before heavy panels
  5. Wait for Config.ready
  |
Config.ready fires:
  1. Apply current theme (ThemeService.applyCurrentTheme)
  2. Initialize icon theme
  3. Migrate enabledPanels if needed
  4. Load the selected family's critical host
  5. Start shell entry timer (200ms when animations are enabled)
  |
Critical panel loading:
  - ii: background + selected bar/vertical bar + dock
  - Waffle: taskbar + background + backdrop
  |
Shell entry frame completes
  |
500ms deferred phase:
  - GameMode, WindowPreviewService, Weather, VoiceSearch, FontSyncService,
    CavaTheme, Hyprsunset
  - GlobalStates.deferredPanelsReady = true
  - ShellIiPanels/ShellWafflePanels wrapper loads its Shell*PanelsImpl tree
  |
~1500ms late phase:
  - ShellUpdates, Autostart, CalendarSync, Todo, Notepad
  |
Shell fully operational
```

## Service wiring

The service tier is selected by capability, not simply by distro name. If a
usable systemd user manager exists, iNiR uses the systemd wiring below. If it
does not, the supported Void path uses Turnstile/runit and falls back to one
Niri-owned runsvdir only when Turnstile is unavailable.

### systemd user-manager tier

The systemd service does not use `systemctl enable` in the traditional sense because there's no `[Install]` section. iNiR is Niri-only, so it creates a wants link from `niri.service`:

`~/.config/systemd/user/niri.service.wants/inir.service`

`inir.service` is ordered **after** the `Type=notify` Niri service and requires it to be active. This means iNiR starts only after Niri has published the authoritative graphical-session environment, and stops/restarts with Niri. It will never accidentally start under KDE, GNOME, or another compositor.

Managing the link:

```bash
inir service enable    # create the wants link
inir service disable   # remove it
inir service status    # check current state
```

### Void runit/Turnstile tier

Setup renders `~/.config/service/inir/run` and selects one non-systemd owner:

- Turnstile: `runsv` starts iNiR with the session envdir updated from Niri;
- fallback: Niri starts a single `runsvdir ~/.config/service` process.

The launcher uses `sv` for service control and status when this tier is active.
The Turnstile handoff propagates values such as `WAYLAND_DISPLAY`,
`NIRI_SOCKET` and the session D-Bus address before the shell is restarted. This
is startup/session synchronization; Turnstile is not in the hot path of every
keybind.

The Turnstile-owned iNiR run file also sets `QS_DISABLE_POLKIT=1`. Its service
manager lives in an elogind background session without the graphical seat, so
the supported Void profile leaves authentication-agent ownership to the
external polkit agent that Niri starts in the seat0 Wayland session. The plain
runsvdir fallback does not set this override.

## The inir launcher

`scripts/inir` is a 3600+ line bash script that wraps Quickshell. It's not the same as running `qs -c inir` directly:

| | `inir run` | `qs -c inir` |
|---|---|---|
| Environment setup | Sets shell-only Qt policy and inherits Niri's session env | Raw environment |
| Output | Backgrounded, logs through the active supervisor/runtime path | Foreground, direct stdout |
| Crash recovery | Active supervisor restarts the managed shell | None |
| ABI check | Validates Quickshell/Qt compatibility | None |
| Orphan cleanup | Supervisor-aware iNiR cleanup removes owned stale runtime/helpers | None |

Do not use raw `qs -c inir` as the normal development path: it bypasses iNiR's launcher/runtime ownership and can duplicate or desynchronize the supervised session. Use `inir logs`, `inir logs --full`, `inir logs --debug`, `inir restart`, and `inir doctor`/`inir repair` instead. `inir logs --debug` deliberately stops the supervised shell and launches the resolved runtime in foreground debug mode through the iNiR control path; after `Ctrl+C`, restore the normal service with `inir restart`.

## Environment variables

The launcher sets these before starting Quickshell:

| Variable | Value | Why |
|----------|-------|-----|
| `QT_SCALE_FACTOR` | `1` | Shell handles its own scaling in QML |
| `QT_SCALE_FACTOR_ROUNDING_POLICY` | `RoundPreferFloor` | Prevents blurry rendering with fractional compositor scaling (1.25 etc) |
| `QT_LOGGING_RULES` | (long list) | Suppress known-harmless Qt/QML warnings |

The launcher also unsets inherited DPI variables that would cause blur: `QT_WAYLAND_FORCE_DPI`, `QT_FONT_DPI`, `QT_AUTO_SCREEN_SCALE_FACTOR`, `QT_SCREEN_SCALE_FACTORS`, `GDK_SCALE`, `GDK_DPI_SCALE`.

The `--session` flag (used by the supported supervisors) consumes the graphical environment that Niri has already published to the selected session-management path. iNiR does not guess compositor sockets. On the systemd tier it consumes the user-manager environment; on Turnstile/runit the explicit environment handoff carries the same authoritative values into the service.

## Config loading

`Config.qml` uses Quickshell's `FileView` to read the user's JSON config file. The loading sequence:

1. The canonical user config is `~/.config/inir/config.json`. `Config.qml` reaches it through `Directories.shellConfigPath`; migrated installs expose the legacy `~/.config/illogical-impulse` path as a compatibility link, while the resolver still honors an older real legacy directory.
2. JsonAdapter parses the content
3. Schema properties bind to parsed values (with fallbacks)
4. `Config.ready` becomes true
5. Everything that was waiting on config starts loading

If the config file doesn't exist (fresh install), Config creates it from `defaults/config.json`.

Hot-reload: if you edit config.json externally, FileView detects the change and re-parses within 50ms.

## Panel loading

Panel composition is split so startup-critical surfaces are not blocked by the full module tree.

`shell.qml` loads one of:

- `modules/ii/critical/ShellIiCriticalPanels.qml`
- `modules/waffle/critical/ShellWaffleCriticalPanels.qml`

After `GlobalStates.deferredPanelsReady`, it loads the thin family wrapper, which delegates to the ii, Waffle, or iRiS `Shell*PanelsImpl.qml` composition root.

The family implementation then chooses between ordinary, deferred and on-demand loaders. A typical deferred/on-demand panel still uses the same identifier contract:

```qml
OnDemandPanelLoader {
    identifier: "iiOverview"
    open: GlobalStates.overviewOpen
    source: "../overview/Overview.qml"
}
```

A panel's exact lifecycle depends on its loader, but common gates include:

1. `Config.ready` is true
2. The identifier exists in `Config.options.enabledPanels`
3. `extraCondition` evaluates to true when present
4. The relevant startup/open-state gate is satisfied

The critical first-frame set is intentionally small:

**ii**: background, selected horizontal/vertical bar, dock.

**Waffle**: taskbar, background, backdrop.

Notification/OSD feedback and the rest of the family tree are part of the deferred implementation phase; interaction-heavy surfaces such as overview, sidebars, launchers and dialogs can stay unloaded until opened.

## Crash recovery

On the systemd tier the service has:

- `Restart=on-failure` with `StartLimitBurst=3` and `StartLimitIntervalSec=30`
- If iNiR crashes, systemd restarts it (up to 3 times in 30 seconds)
- `ExecStopPost` runs `inir cleanup-orphans` to clear stale Quickshell runtime entries
- Exit code 143 (SIGTERM) is treated as success, not failure

On the Void non-systemd tier, runit provides the restart loop instead. Session
boot also removes only iNiR-owned orphaned helpers (for example old `swayidle`
or keyboard-lock daemon instances) before starting the next shell. This avoids
the duplicate-helper leak found during the external-disk validation without
killing unrelated user processes.

## Deferred initialization

Display/interaction services load 500ms after the first frame to reduce boot contention:

- GameMode (fullscreen detection)
- WindowPreviewService (alt-tab previews)
- Weather (API polling)
- VoiceSearch (Gemini transcription)
- FontSyncService (GTK/KDE font sync)
- CavaTheme (audio visualizer theme state)
- Hyprsunset (night light)

A second late tier starts roughly 1000ms later and materializes ShellUpdates, Autostart, CalendarSync, Todo, and Notepad. This keeps network/file-I/O background work out of the first-frame contention window.

## Debugging startup

If the shell won't start or you need foreground diagnostics:

```bash
# Normal recent runtime logs
inir logs

# Decode all recorded log categories
inir logs --full

# Foreground debug run through iNiR's runtime resolver
inir logs --debug

# Automated health/repair flows
inir doctor
inir repair
```

After leaving `inir logs --debug` with `Ctrl+C`, run `inir restart` to return to the normal supervised runtime.

## Performance diagnostics

`inir doctor --perf` prints a read-only snapshot of the running shell. It reports
process memory and threads, the observed Qt Quick RHI and render loop, DRM render
nodes, Qt Multimedia decoder ownership, open video and GIF files, mapped Niri
layer surfaces, child processes, and the `inir.service` cgroup.

```bash
inir doctor --perf
```

Use it before changing graphics environment variables or blaming one feature for
the complete service cgroup. The snapshot distinguishes Quickshell from helpers
and applications, and flags duplicate media files opened by more than one
renderer.
