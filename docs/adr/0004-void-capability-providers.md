# ADR-0004: Void capabilities require a complete provider contract

An integration is supported on Void only when iNiR can provision its provider,
activate any required service, operate it through the existing UI, and verify
the result. Merely detecting a binary or leaving a visible control that fails
is not support.

Provider resolution follows this order:

1. an official XBPS package;
2. a maintained Flatpak when the application is suitable for Flatpak;
3. an upstream binary or source build with pinned provenance and an explicit
   update path.

The normal Void installer mirrors the Arch dependency profiles: base, audio,
toolkit, screencapture, and fonts/theme. Selecting a profile provisions every
provider required by that profile. System-service activation remains a
separate, confirmed elevation step and uses runit on Void.

A capability contract contains five independently testable parts:

- **provider**: package, Flatpak ID, or pinned upstream source;
- **provisioning**: an idempotent installer or repair path;
- **activation**: runit, turnstile user service, or direct session process;
- **operation**: the existing iNiR UI action works without distro knowledge;
- **verification**: a repeatable local or Void VM check.

Controls without a complete contract must not claim that the capability is
available on Void, and a capability Void lacks is never removed for the other
distributions: it is gated on what the host has. Game Mode's `discover-overlay`
control runs and shows only where `discover-overlay` is installed.

Status: accepted for the remaining Void V1 work.
