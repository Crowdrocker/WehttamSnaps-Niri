# ADR-0003: Single startup template with per-distro injection

`defaults/niri/config.d/50-startup.kdl` is the single source. Setup renders
the supervisor-specific managed blocks into the user's split startup file, or
the monolithic `config.kdl` when no split file exists.

The template keeps the systemd environment command as the default and does
not contain a runsvdir entry. Setup injects exactly one of the following
managed blocks:

- `inir-systemd-environment` for a usable systemd user manager
- `inir-runsvdir-fallback` for the non-systemd fallback

Injection is idempotent and removes legacy unmarked entries owned by iNiR.
Migration 021 also removes the runsvdir block when the systemd predicate holds,
so the two startup paths cannot create two shells.

Status: accepted and VM validated.
