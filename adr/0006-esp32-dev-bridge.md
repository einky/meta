# ADR 0006: ESP32 e-ink dev bridge

- Status: Accepted
- Date: 2026-06-30

## Context

During development the real Pi + GDEM0397T81P panel is often unavailable
(hardware in transit, flashing an SD card is slow, the GPIO-less QEMU `virt`
target can't drive a panel). We still want to see frames on a *real* e-ink panel
and drive them with *real* buttons. An ESP32 wired to a spare Waveshare 7.5"
800×480 panel stands in for the Pi: it receives frames over WiFi and sends
button presses back.

Two implementations existed and diverged:

1. `runtime/firmware/esp32/` — raw **TCP**, the `"EINK"` binary framing from
   `runtime/src/frame_processor/dispatch.py`, 7 buttons matching
   `runtime/src/input/keymap.py`, config in `include/config.h`.
2. `launcher/bridge/` — an **HTTP** server on the ESP32 (`POST /frame`,
   `/partial`, `GET /input`) paired with a standalone `einky_bridge.py` that
   re-implemented capture + dither.

Maintaining both means two protocols, two button sets, and a second copy of the
frame pipeline.

## Decision

Keep **one** bridge: the **TCP firmware in `runtime/firmware/esp32/`**, because
it already speaks the tested `dispatch.py` frame protocol and the
`net_handler.py` input protocol, and its button names match the shared keymap.
Retire `launcher/bridge/` (firmware + `einky_bridge.py`) entirely.

The bridge is a **dev tool only** — it is never part of a shipping image. Its
frame/input framing and button/pin map are defined by the shared contract
(`meta/shared/hardware.toml`, `meta/shared/protocol.md`); `include/config.h` is
generated/derived from that table.

`start` maps to ESP32 GPIO 12, a strapping pin that must read LOW at boot; a
button-to-GND satisfies this, but if a board boots intermittently, move it to a
non-strapping pin in the contract and regenerate.

## Consequences

- One protocol (`EINK` over TCP), one button set, one frame pipeline (`runtime`).
- WSL users need mirrored networking or a port-proxy for the ESP32 to reach the
  host listener (documented in `runtime/firmware/esp32/README.md`).
- `launcher` loses the `bridge/` directory; the `docs` ESP32 page documents the
  TCP bridge only.
