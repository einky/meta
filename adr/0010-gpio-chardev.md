# ADR 0010: All GPIO goes through the gpiochip character device (libgpiod v2)

- Status: Accepted
- Date: 2026-07-07

## Context

Until now the two GPIO consumers used two different stacks:

- **Buttons** (`runtime` input handler, `launcher` `GpioSource`): `gpiozero`
  with the `rpigpio` (RPi.GPIO) pin factory, chosen in the InkyOS bring-up
  because gpiozero's preferred `lgpio` factory is not packaged in Buildroot.
- **Panel control lines** (DC/RST/BUSY in the C SPI driver): libgpiod **v1**,
  because Buildroot's default `libgpiod` package was 1.6.x.

First hardware bring-up (2026-07-07) proved the button stack dead on arrival:
RPi.GPIO implements *edge detection* through the legacy `/sys/class/gpio`
interface using raw BCM numbers. On kernels ≥ 6.6 the Pi's gpiochip sits at a
dynamic global base (512+), so every export fails (`export_store: invalid
GPIO 5` in the kernel log) and the launcher crash-loops under the supervisor.
This is unfixable upstream — RPi.GPIO never migrated off sysfs (Raspberry Pi
OS replaced it with an `lgpio` shim for the same reason) — and every other
gpiozero factory is equally unusable here: `native` is also sysfs-based,
`lgpio`/`pigpio` are not packaged in Buildroot.

What Buildroot 2026.05 *does* package is the modern stack: `libgpiod2` 2.2.4
and `python-gpiod` 2.4.2 — the GPIO v2 character-device uAPI, with kernel-side
bias (pull-up), debounce, and edge events.

## Decision

One GPIO stack for everything: the **gpiochip character device**.

- Buttons are read by a new shared reader, `runtime` `input.gpio_reader
  .GpioButtonReader` (python-gpiod): pull-up bias, the contract's 30 ms
  debounce, press = falling edge, plus optional hold detection (the
  launcher's hold-Start-to-quit). Both consumers — the launcher's
  `GpioSource` and the runtime's `inky-input` — use this one reader
  (ADR 0008: the runtime owns shared on-device logic). `gpiozero`,
  `RPi.GPIO`, and `colorzero` are dropped entirely.
- The C SPI driver's DC/RST/BUSY handling is ported from libgpiod v1 to the
  **v2 API** (one bulk line request). Buildroot's `python-gpiod` is declared
  incompatible with `libgpiod` v1, so v2 everywhere is also the only
  packageable combination.
- The gpiochip path is one env flip-point for the whole device:
  `EINKY_GPIOCHIP` (default `/dev/gpiochip0`), used by both the reader and
  the C driver.

## Consequences

- The Pi image's toolchain moves from Bootlin **stable** to **bleeding-edge**
  (`configs/inky_defconfig`): libgpiod2/python-gpiod need kernel headers
  ≥ 5.10 for the v2 uAPI and the stable toolchain ships 5.4. The device
  kernel is 6.12, so newer headers are the better match anyway. Cost: a
  toolchain switch rebuilds every target package once; gcc moves 14 → 15.
  The QEMU target keeps its internal Buildroot toolchain (no GPIO on QEMU).
- `/dev/gpiomem` and the sysfs GPIO interface are no longer needed by
  anything on the image.
- Kconfig hygiene learned the hard way (the colorzero trap): a `select` of a
  symbol whose own dependencies are unmet is force-applied while that
  symbol's *own* selects are silently dropped. `BR2_PACKAGE_INKY_RUNTIME_SPI`
  therefore repeats python-gpiod's headers dependency instead of relying on
  transitive selects.
- `libgpiod2-tools` (`gpioinfo`/`gpioget`/`gpioset`) ship on the hardware
  image for bring-up debugging of the remaining flip-points (BUSY polarity,
  `EINKY_INVERT_FRAME`).
