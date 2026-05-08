# ADR 0005: The launcher is itself a Ren'Py game

- Status: Accepted
- Date: 2026-05-08

## Context

When the device boots, the user lands in a fullscreen UI that lists
installed games and starts the one they pick. We need to choose what
technology that "shell" is built in.

Options considered:

1. **A Ren'Py project** — same engine as the games, same SDK installed once
   on the device, same skill set across the team.
2. **A native GUI (Qt/GTK/SDL)** — lower memory footprint but a second
   stack, second build pipeline, second skill requirement.
3. **A web UI in a kiosk browser** — flexible, but adds Chromium to the
   image (RAM, update surface) and complicates input handling.

Operationally, the launcher does the same things a game does: render a
screen, handle controller/keyboard input, transition between menus, play
audio. The unusual part is what it does *between* selection and the next
screen — exec the chosen game and exit cleanly so the runtime can manage
the lifecycle.

## Decision

Build the launcher as a **Ren'Py project**, run by the same SDK installed
for games. The runtime (`runtime/`) is responsible for starting the
launcher process, watching it, and switching between launcher and game
processes on selection / on game exit.

## Consequences

- One engine on the device, one set of skills on the team, one set of
  upgrade and SHA256 checks.
- Launcher screens and game UI components can share Ren'Py idioms, fonts,
  and theming.
- Process lifecycle (launcher exits → runtime spawns chosen game → game
  exits → runtime respawns launcher) is owned by `runtime/`, not by
  Ren'Py. Keeping that boundary clean is critical: the launcher must not
  try to `exec` games itself.
- A future shell rewrite (e.g. for performance reasons on lower-end
  hardware) is contained — the runtime contract is the only thing the
  rest of the system depends on, not the fact that the shell happens to
  be Ren'Py.
