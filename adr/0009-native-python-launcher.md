# ADR 0009: The launcher is a native Python renderer, not a Ren'Py game

- Status: Accepted
- Date: 2026-07-06
- Supersedes: [ADR 0005](0005-launcher-as-renpy-game.md)

## Context

ADR 0005 built the launcher as a Ren'Py project, on the theory that the shell
does the same things a game does (render, take input, transition). In practice
the launcher's job is the *opposite* of a game's on this hardware:

- The panel is **800×480 1-bit e-ink at ~2 FPS**, and the Pi Zero 2 W has **512
  MB RAM and no usable GPU GL**. Ren'Py needs Xvfb + Mesa `llvmpipe` software GL
  + SDL just to draw a menu — tens of seconds of cold-start and hundreds of MB
  RSS to render static black-and-white lists.
- Ren'Py's value (animation, transitions, ATL, audio, a scripting VM) is
  meaningless for a menu on a 2 FPS 1-bit panel, and its frame model gives the
  launcher no control over the one thing that matters here: **partial vs full
  e-ink refresh**.
- ADR 0005 kept process lifecycle in `runtime/` and forbade the launcher from
  `exec`-ing games. That split turned out to be awkward: someone has to own the
  panel (a single `/dev/spidev0.0` opener) and the buttons (a single gpiozero
  owner) across the launcher↔game handoff, and bouncing that ownership between
  two processes is the fiddly part.

By the time ADR 0008 landed, all the hard pieces already existed in `runtime/`
as importable Python: the SPI panel driver, the capture→dither→pack pipeline,
the contract keymap, and the in-engine input/frame sockets a game speaks.

## Decision

Build the launcher as a **lightweight pure-Python application** (`launcher/`,
package `einky-launcher`) that:

- renders 1-bit frames with **Pillow** and pushes them through the shared
  `runtime` panel driver (`spi_driver.open_panel`), choosing partial vs full
  refresh itself;
- reads the 7 GPIO buttons directly via the `runtime` keymap (no
  xdotool/Xvfb for its *own* UI);
- **owns the panel (SPI) and the buttons (GPIO) for the whole uptime** and
  spawns Ren'Py games as supervised child processes, bringing up Xvfb on demand
  and bridging each game's frames/input over the engine-capture sockets
  (`renpy-eink.sock` / `renpy-input.sock`) that `runtime` already defines.

`inky-session` shrinks to "supervise `inky-launcher`". It consumes `runtime`
(ADR 0008) — it does not reimplement the dither/pack/driver.

## Consequences

- **Instant boot to UI, tight refresh control.** No X/GL stack for the menu; the
  launcher picks partial refresh for cursor moves and full refresh for screen
  changes / ghost-clearing, tunable from Settings.
- **One owner, clean handoff.** The launcher holds SPI+GPIO for the whole
  session; games never touch either, eliminating the contention ADR 0005's
  split created. This also enables a global "hold Start to exit game" combo.
- **The GPIO→xdotool→Xvfb input path is gone** for the launcher; games receive
  input over the in-engine socket (already proven on the emulator), removing the
  unvalidated keysym-injection chain from the hardware bring-up.
- **Two stacks on the device** (Python launcher + Ren'Py games) instead of one —
  the cost ADR 0005 avoided. Justified: the launcher is ~2k lines of Python
  reusing proven `runtime` code, and the two stacks already coexist (games are
  Ren'Py regardless).
- A future shell rewrite stays contained: the launcher depends only on the
  `runtime` contract (driver + sockets + keymap), same as before.

## Status of the implementation

Milestones M0–M4 are implemented and verified on the QEMU emulator target: host
unit/integration tests, plus on-image drives that boot the launcher, launch and
exit the real `the_question` Ren'Py game, change + persist settings across a
UI-triggered reboot, and run the Wi-Fi join flow (mock backend). Hardware
bring-up (SPI/GPIO backends, panel refresh tuning, real Wi-Fi) is M5.
