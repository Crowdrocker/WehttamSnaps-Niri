# ADR-0002: The "usable systemd user manager" predicate governs the port

Void can run systemd; an Arch box can lack a working user manager. Every
systemd-sensitive path in iNiR is therefore gated by a predicate, not by
`command -v systemctl` and not by distro name.

The predicate: the socket `$XDG_RUNTIME_DIR/systemd/private` exists
(`/run/user/$UID` when the variable is unset) and a bounded probe of
`systemctl --user` answers or times out:
`timeout 3s systemctl --user show-environment`. The socket only exists while
the manager runs, so a timeout is a busy manager, still systemd; reading it as
runit would move a systemd host to `runsvdir`.

Paths it gates:

- install: `inir.service` unit vs `~/.config/service/inir/run`
- migrations 021/022
- `scripts/inir`: restart/kill/stop/status/logs
- runtime UI and environment operations that use `systemctl --user` or
  `systemd-run`
- distribution-test invariants

Without the socket, `systemctl --user` can block for 10-30 seconds, so the
socket check comes first and the probe is bounded.

Status: accepted and verified across runtime and maintenance paths. Future
systemd-sensitive work remains subject to this predicate.
