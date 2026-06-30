# einky — Wire Protocols

> Authoritative spec for the byte-level contracts between the frame/input
> producers and consumers. Constants (ports, magic, socket paths, panel size)
> live in [`hardware.toml`](./hardware.toml); this file explains the framing.
> Any implementation in any repo MUST match this document.

## The unified frame pipeline

There is **one** processing pipeline and **one** panel-facing frame format. The
only thing that varies is where the image is *captured* and where the bytes are
*dispatched*:

```
 capture (one of)                process (single impl)              dispatch (one of)
┌────────────────────────┐
│ external: xwd / mss     │──┐
│   → RGB framebuffer     │  │   greyscale → Floyd–Steinberg     ┌── SpiSink      → panel (SPI)
├────────────────────────┤  ├──→  dither → pack 1-bit (MSB) ──┬─┼── SocketSink   → tools/preview.py
│ in-engine: Ren'Py       │  │   (runtime frame_processor)      │ └── TcpFrameSink → ESP32 bridge
│  eink_push_callback     │──┘                                  │
│   → PNG over socket      │  (PNG is decoded, then same path)   └── (input flows back the other way)
└────────────────────────┘
```

The dither + pack + dispatch implementation is owned by **`runtime`**
(`src/frame_processor/`). `buildroot_os` consumes it as a Buildroot package; no
one else reimplements it. See [ADR 0008](../adr/0008-shared-hardware-contract.md).

## Frame protocol (`[protocol.frame]`)

Length-prefixed, little-endian. Identical on the Unix-socket (`preview`) and TCP
(ESP32) transports. One frame per send; the connection stays open across frames.

```
| 4 bytes | 4 bytes  | 4 bytes  | N bytes          |
| "EINK"  | u32 width| u32 height| packed 1-bit     |
```

- `N` = `width / 8 * height` = **48000** bytes for the production panel.
- Packing: MSB-first, **bit = 1 → white** (numpy `packbits` of `grey >= 128`).
  The SPI driver and the ESP32 firmware **invert** before drawing, because
  `GxEPD2::drawBitmap` / the panel treat bit = 1 as the black foreground.
- A full refresh is forced every `full_refresh_every` (30) frames to clear
  e-ink ghosting; otherwise partial refresh.

## Input protocol (`[protocol.input]`)

Newline-delimited ASCII **button names** (not keysyms), from
[`hardware.toml`](./hardware.toml) `[[button]].name`:

```
up\n  down\n  left\n  right\n  a\n  b\n  start\n
```

The receiver looks the name up in the shared button table and injects the
mapped `keysym` (X stack, via `xdotool`/`uinput`) or queues the `renpy_events`
(in-engine path). The name table is the single source of truth across every
transport — GPIO, TCP-from-ESP32, and the in-engine socket.

## In-engine capture protocol (`[protocol.engine_capture]`)

`buildroot_os` runs the capture *inside* Ren'Py via `config.eink_push_callback`
(`eink_hook.rpy`). Each stable frame is shipped to a receiver over a Unix
socket:

```
| 4 bytes          | M bytes |
| u32 length (BE)  | PNG     |
```

The receiver decodes the PNG and feeds it into the **same** greyscale → dither →
pack → dispatch path as the external-capture stack, producing the standard
frame-protocol bytes for the panel. Input on this path uses the same
`ascii-lines` format over `input_socket`, consumed by `input_hook.rpy`.
