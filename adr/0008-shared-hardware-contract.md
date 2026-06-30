# ADR 0008: Shared hardware contract and single-owner shared logic

- Status: Accepted
- Date: 2026-06-30

## Context

A cross-repo audit found the same logic implemented several times, drifting
apart:

- the **e-ink frame pipeline** (capture → dither → pack → dispatch) existed in
  `runtime/src/frame_processor/`, `launcher/bridge/einky_bridge.py`, and the
  `buildroot_os` in-engine hook;
- the **button/keymap** was defined four times with conflicting names and pins
  (`runtime` keymap, the two ESP32 firmwares, the buildroot `input_hook`);
- the **pinout** had three claimed "sources of truth" (an absent
  `case/docs/wiring.md`, `docs/hardware/wiring.md`, and `spi_driver.h`);
- there were **two SDK installers** (one pinned, one fetching latest with no
  hash) and **scattered version pins**.

We are a polyrepo with no monorepo build system ([ADR 0001]), so we cannot just
drop a shared library that everyone imports at build time.

## Decision

Two complementary rules.

1. **Shared *data* lives in `meta/shared/`.** The panel geometry, GPIO/SPI pin
   map, button bindings, and wire-protocol constants are defined **once** in
   `meta/shared/hardware.toml` + `meta/shared/protocol.md`. Every repo derives
   its constants from that file (symlink, build-time codegen + CI parity check,
   or direct read) and never hard-codes or forks them. Version pins stay in
   `meta/versions.env`; the SDK installer is the single pinned
   `meta/scripts/install-renpy-sdk.sh`.

2. **Shared *logic* has exactly one owner.** Rather than a shared code repo, the
   canonical implementation lives in the repo best positioned to own it, and
   others consume it:
   - frame pipeline + SPI driver + input/keymap → **`runtime`**;
   - `buildroot_os` consumes `runtime` as a Buildroot package (`inky-runtime`)
     instead of re-coding capture/dither/SPI/uinput;
   - the ESP32 dev bridge → **`runtime/firmware/esp32`** (TCP); `launcher/bridge`
     is retired ([ADR 0006]);
   - `games/` holds only games — the misfiled SDK project browser
     (`games/launcher`) is removed; the einky shell is `launcher/launcher`.

## Consequences

- One pinout, one keymap, one frame pipeline, one ESP32 firmware, one SDK
  installer — bump-once semantics with CI parity checks.
- `buildroot_os` gains its missing on-device dither/SPI/input by packaging
  `runtime`, not by writing new C/Python.
- Cross-repo changes to the contract are a `meta` PR plus regenerations in
  consumers (called out per [CONTRIBUTING.md](../CONTRIBUTING.md)'s cross-repo
  rule).
- New dependency direction: `runtime` ← `buildroot_os`, and every repo ←
  `meta/shared`. These are documented and narrow.

[ADR 0001]: 0001-polyrepo.md
[ADR 0006]: 0006-esp32-dev-bridge.md
