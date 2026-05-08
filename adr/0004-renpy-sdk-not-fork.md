# ADR 0004: Use the upstream Ren'Py SDK, do not fork it

- Status: Accepted
- Date: 2026-05-08

## Context

Both the launcher and our games are built on Ren'Py. We need a way to ship
the Ren'Py engine on the device and to use it on developer machines. The
question is whether to fork Ren'Py (so we can patch the engine) or to depend
on the official upstream SDK release as an opaque tarball.

Forking is tempting because the launcher behaves more like an OS shell than
a visual novel — full-screen, no window chrome, custom input handling, no
quit-to-desktop — and we will hit edges of the engine. But forking carries
real cost: tracking upstream, rebuilding for x86_64 *and* aarch64, cherry-
picking security fixes, and divergence from community documentation.

## Decision

**Do not fork Ren'Py.** Depend on the official SDK at a pinned version
(`RENPY_SDK_VERSION` in `versions.env`), downloaded with SHA256 verification
by `scripts/install-renpy-sdk.sh`. Customize behavior entirely from inside
our Ren'Py projects (the launcher and games) using the engine's hook points
(`config.*`, `python` blocks, screen overrides).

If we hit an engine limitation we cannot work around from project code, we
re-evaluate this ADR rather than silently start patching.

## Consequences

- Engine upgrades are a single line in `versions.env` plus a re-run of
  `sha256sum` — trivial to bump and easy to roll back.
- We can use community examples and documentation directly; no
  "but-our-fork-does-X" footnotes.
- Some launcher features (e.g. low-level input grab, custom video pipeline)
  may require ugly workarounds inside project code. We accept that
  trade-off as the price of staying on mainline.
- The pinned SHA256 is mandatory — a missing or mismatched hash fails the
  install loudly, preventing supply-chain surprises.
