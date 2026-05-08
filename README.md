# meta

Dev-workspace entry point for **Crab-Ink-Gaming**. Clone this repo first, then
run `./bootstrap.sh` to clone every other org repo as a sibling directory.

## Repo layout

After bootstrapping, your workspace should look like:

```
einky/                         # parent dir (name is up to you)
├── meta/                      # ← you are here
├── .github/                   # org-wide GitHub config, workflows, profile
├── docs/                      # human-readable design docs and guides
├── os/                        # pi-gen-based Raspberry Pi OS image build
├── runtime/                   # on-device Python runtime that launches games
├── launcher/                  # Ren'Py-based front-end / game picker
├── server/                    # FastAPI backend (game catalog, telemetry)
├── web/                       # web frontend (admin / store / management)
├── case/                      # hardware: enclosure CAD, BOM, wiring
└── games/                     # Ren'Py game projects
```

| Repo | Purpose | Link |
|---|---|---|
| [meta](https://github.com/Crab-Ink-Gaming/meta) | Workspace bootstrap, ADRs, shared scripts | this repo |
| [.github](https://github.com/Crab-Ink-Gaming/.github) | Org profile, shared workflows, issue templates | [→](https://github.com/Crab-Ink-Gaming/.github) |
| [docs](https://github.com/Crab-Ink-Gaming/docs) | Architecture docs, onboarding, guides | [→](https://github.com/Crab-Ink-Gaming/docs) |
| [os](https://github.com/Crab-Ink-Gaming/os) | pi-gen recipe producing the device OS image | [→](https://github.com/Crab-Ink-Gaming/os) |
| [runtime](https://github.com/Crab-Ink-Gaming/runtime) | On-device service that runs the launcher and games | [→](https://github.com/Crab-Ink-Gaming/runtime) |
| [launcher](https://github.com/Crab-Ink-Gaming/launcher) | Ren'Py game selector shown at boot | [→](https://github.com/Crab-Ink-Gaming/launcher) |
| [server](https://github.com/Crab-Ink-Gaming/server) | FastAPI backend | [→](https://github.com/Crab-Ink-Gaming/server) |
| [web](https://github.com/Crab-Ink-Gaming/web) | Web frontend | [→](https://github.com/Crab-Ink-Gaming/web) |
| [case](https://github.com/Crab-Ink-Gaming/case) | Enclosure / hardware design | [→](https://github.com/Crab-Ink-Gaming/case) |
| [games](https://github.com/Crab-Ink-Gaming/games) | Ren'Py game sources | [→](https://github.com/Crab-Ink-Gaming/games) |

## Prerequisites

- `git` (≥ 2.30)
- `bash` (≥ 4)
- `curl`, `tar`, `sha256sum`
- `docker` and `docker compose` (for the local dev stack)
- `python` 3.11 (see `versions.env`)
- An SSH key registered with GitHub, if you plan to use `--ssh`

## Bootstrap workflow

```bash
git clone https://github.com/Crab-Ink-Gaming/meta.git
cd meta
./bootstrap.sh                # https (default)
./bootstrap.sh --ssh          # ssh remotes instead
```

The script clones each sibling repo into `..` next to `meta/`. It is
idempotent — already-cloned repos are skipped — and prints a summary of what
was cloned, skipped, or failed.

## Cross-repo pinned versions

All shared version pins live in [`versions.env`](./versions.env). Other repos
source this file (or symlink to it) so a single bump propagates everywhere.

## Local dev stack

```bash
docker compose -f compose/docker-compose.dev.yml up
```

Mounts `../server` and `../web` as volumes so local edits live-reload against
Postgres.

## ADRs

Architecture Decision Records live in [`adr/`](./adr/). New decisions should
follow the same one-page Context / Decision / Consequences format.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).
