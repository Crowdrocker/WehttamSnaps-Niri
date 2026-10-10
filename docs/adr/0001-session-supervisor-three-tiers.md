# ADR-0001: Session supervisor in non-systemd = three tiers, not a respawn loop

On distros without a usable systemd user manager (default Void/runit), iNiR
loses the `Restart=on-failure` supervision of `inir.service`. We chose a
three-tier session supervisor instead of (a) a respawn loop in
`spawn-sh-at-startup` — rejected because `inir run --session` does `exec qs`,
so `inir kill` (SIGTERM, exit 143) respawns a deliberately killed shell and
`inir restart` races the loop into two shells — and (b) no supervision —
rejected because a crash would leave the shell dead until Niri restarts.

Tiers, in order of preference, decided by the usable-systemd-user-manager
predicate (ADR-0002), never by distro name:

1. **systemd user unit** (`inir.service`) — when the predicate holds.
2. **turnstile user service** (`~/.config/service/inir/run`) — when the
   `turnstiled` service is running. Turnstile can manage the session D-Bus bus
   and export environment through `TURNSTILE_ENV_DIR`.
3. **runsvdir spawned by Niri** (`spawn-sh-at-startup "exec runsvdir
   ~/.config/service"`) — zero-dependency fallback. Niri kills its spawns on
   exit, giving session lifetime for free.

Tiers 2 and 3 share the same `~/.config/service/inir/run` file. Only one
session tier may own that directory at a time. Turnstile's backend may itself
run `runsvdir`; this is not the Niri fallback and does not create a second
shell.

Status: accepted and VM validated.
