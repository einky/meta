# ADR 0002: Build the device OS with pi-gen

- Status: Accepted
- Date: 2026-05-08

## Context

The device boots into our launcher on a Raspberry Pi. We need a reproducible,
auditable way to produce the SD-card image with our runtime, launcher, system
tweaks (read-only rootfs, kiosk session, autologin, splash), and pinned
package versions baked in.

Options considered:

1. **pi-gen** — the official Raspberry Pi OS image builder. Stage-based,
   shell-script driven, runs in Docker, produces the same kind of image
   Raspberry Pi ships.
2. **Yocto / buildroot** — full custom Linux distro. Maximum control but
   weeks of setup, and we lose easy access to apt packages.
3. **Stock Raspberry Pi OS + first-boot script** — fast to start but image
   contents drift with whatever apt mirrors return on first boot.

## Decision

Use **pi-gen** with a custom stage that installs the runtime, launcher, and
configures the kiosk session. Track upstream pi-gen on the `arm64` branch
(pinned via `PI_GEN_BRANCH` in `versions.env`).

## Consequences

- Image builds are reproducible-enough: same pi-gen branch + same apt
  snapshot + same versions.env produces the same image.
- We inherit Raspberry Pi's apt sources, kernel, and firmware — low
  maintenance, well-tested on the target hardware.
- Stage scripts are bash, which limits sophisticated logic. We accept that;
  anything complex belongs in `runtime/` and runs on-device.
- Builds need Docker and ~10 GB free disk. CI runs them on a self-hosted
  runner; local builds are documented in `os/README.md`.
- If we later need a stripped-down image (no apt, immutable rootfs) we can
  migrate to buildroot without changing the runtime contract.
