# `meta/shared/` — cross-repo source of truth

This directory is the **global-scope home for things that were previously
duplicated** across `runtime`, `launcher`, `buildroot_os`, and the ESP32
firmware. It holds *contracts and data*, not built code — in a polyrepo, the
shared **logic** stays owned by one repo and is consumed by the others (see the
ownership map below and [ADR 0008](../adr/0008-shared-hardware-contract.md)).

## Files

| File | What | Authority over |
|---|---|---|
| [`hardware.toml`](./hardware.toml) | Panel geometry, SPI + button GPIO map, button→key/event bindings, protocol constants | The pinout (D4) and the keymap (D3) |
| [`protocol.md`](./protocol.md) | Byte-level frame + input + in-engine wire protocols | The wire formats (D1/D2) |
| [`../versions.env`](../versions.env) | Pinned tool/engine versions | Version pins (D7) |
| [`../scripts/install-renpy-sdk.sh`](../scripts/install-renpy-sdk.sh) | The **one** SDK installer (pinned + SHA256) | SDK install (D6) |

## Ownership map (who owns the shared *logic*)

| Concern | Canonical owner | Everyone else |
|---|---|---|
| Frame capture → dither → pack → dispatch | `runtime/src/frame_processor/` | `buildroot_os` consumes it as a Buildroot package; `launcher` no longer ships its own |
| SPI panel driver (C) | `runtime/src/spi_driver/` | consumed by `buildroot_os` |
| GPIO / net / in-engine input + keymap | `runtime/src/input/` (table from `hardware.toml`) | `buildroot_os` input_hook + ESP32 firmware derive from the same table |
| ESP32 dev-bridge firmware | `runtime/firmware/esp32/` (TCP) | `launcher/bridge/` is **retired** |
| Hardware contract (this dir) | `meta` | all repos generate constants from it |

## How a repo consumes the contract

Repos do **not** copy these values. They either:

1. **Symlink** the file (same pattern as `runtime/scripts/install-renpy-sdk.sh
   -> ../../meta/scripts/install-renpy-sdk.sh`), or
2. **Generate** language-specific constants from `hardware.toml` at build time
   and commit the generated file with a CI parity check (mirroring the existing
   `install-script-parity` job), or
3. read `../meta/shared/hardware.toml` directly at runtime where practical.

The per-repo refactor prompts specify exactly which approach each repo uses.
Bump a value **here**; downstream regenerates. Never edit a generated copy by
hand.
