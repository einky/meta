# ADR 0007: Migrate the device OS from pi-gen to Buildroot

- Status: Accepted
- Date: 2026-06-30
- Supersedes: [ADR 0002](0002-pi-gen-os.md)
- Amends: [ADR 0004](0004-renpy-sdk-not-fork.md)

## Context

[ADR 0002] built the device image with **pi-gen** (Raspberry Pi OS Lite + a
custom apt/payload stage). That served the early bring-up but hit real limits:

- **Ren'Py needs a desktop-OpenGL/GLX context.** The Pi's VideoCore exposes only
  OpenGL **ES**, the root cause of the `Couldn't find matching GLX visual`
  failure. The robust fix is software desktop GL via **Mesa `llvmpipe`**, which
  is awkward to guarantee reproducibly on a stock Raspberry Pi OS.
- **Appliance posture.** We want no package manager in the boot path, an
  immutable root with a separate writable data partition for save survival, and
  a byte-reproducible image. pi-gen images drift with apt mirror state.
- **Emulation.** We want the *same artifact* we flash to also boot cleanly in
  QEMU for day-to-day development. pi-gen's raspi machine fidelity in QEMU is
  unreliable.

[ADR 0002] explicitly anticipated this exit: *"If we later need a stripped-down
image (no apt, immutable rootfs) we can migrate to buildroot without changing
the runtime contract."*

## Decision

Build the device OS with **Buildroot** as a `br2-external` tree
(`buildroot_os/`, "InkyOS"), replacing `os/` (now archived). Key points:

- **Mesa `llvmpipe`** software desktop GL — identical in QEMU and on hardware.
- **Two non-interchangeable targets**: `inky_defconfig` (Pi Zero 2 W, ships) and
  `inky_qemu_defconfig` (QEMU `virt`, dev). *Develop on the emulator, validate
  on hardware.*
- **Boot-to-game** via the `inky-session` BusyBox-init service.
- **Ren'Py and pygame_sdl2 are built from source** as Buildroot packages, pinned
  in lockstep with the Buildroot toolchain (`meta/versions.env`).

### Amendment to ADR 0004

[ADR 0004] said "use the upstream SDK, do not fork, do not patch." On the device
that is **no longer literally true**: `buildroot_os` compiles the engine from
the upstream **source tarball** and carries exactly one patch
(`package/renpy/0001-add-eink-push-callback.patch`) to add
`config.eink_push_callback`. The *spirit* of 0004 still holds — we track an
unmodified upstream **release**, the patch is tiny, isolated, and re-evaluated
on every bump, and developer workstations still use the vanilla SDK tarball
(`scripts/install-renpy-sdk.sh`). 0004 is amended, not revoked.

## Consequences

- `os/` is deprecated and archived; excluded from all active development and
  consolidation. It remains only for historical image reproducibility.
- The on-device frame/input *logic* contract is unchanged: `buildroot_os`
  consumes `runtime`'s frame pipeline + SPI driver + keymap rather than
  reimplementing them (see [ADR 0008]). The in-engine `eink_push_callback`
  capture feeds that same pipeline.
- `meta/bootstrap.sh`, `meta/versions.env`, and the `docs` site are updated to
  describe Buildroot/InkyOS and drop pi-gen.
- Open design item: reconcile the single-game appliance boot with the
  launcher + multi-game model ([ADR 0005]).

[ADR 0002]: 0002-pi-gen-os.md
[ADR 0004]: 0004-renpy-sdk-not-fork.md
[ADR 0005]: 0005-launcher-as-renpy-game.md
[ADR 0008]: 0008-shared-hardware-contract.md
