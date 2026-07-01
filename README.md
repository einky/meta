# meta

Dev-workspace entry point for **einky**. Clone this repo first, then
run `./bootstrap.sh` to clone every other org repo as a sibling directory.

## Repo layout

After bootstrapping, your workspace should look like:

```
einky/                         # parent dir (name is up to you)
├── meta/                      # ← you are here  (bootstrap, ADRs, shared/ contract)
│   └── shared/                # cross-repo source of truth (hardware.toml, protocol.md)
├── .github/                   # org-wide GitHub config, workflows, profile
├── docs/                      # human-readable design docs and guides
├── buildroot_os/             # InkyOS — Buildroot device image (replaces os/)
├── runtime/                   # on-device frame/input pipeline (owns the shared logic)
├── launcher/                  # Ren'Py-based front-end / game picker
├── server/                    # FastAPI backend (game catalog, telemetry)
├── web/                       # web frontend (admin / store / management)
├── case/                      # hardware: enclosure CAD, BOM, wiring
└── games/                     # Ren'Py game projects
```

| Repo | Purpose | Link |
|---|---|---|
| [meta](https://github.com/einky/meta) | Workspace bootstrap, ADRs, `shared/` contract, shared scripts | this repo |
| [.github](https://github.com/einky/.github) | Org profile, shared workflows, issue templates | [→](https://github.com/einky/.github) |
| [docs](https://github.com/einky/docs) | Architecture docs, onboarding, guides | [→](https://github.com/einky/docs) |
| [buildroot_os](https://github.com/einky/buildroot_os) | **InkyOS** — Buildroot device image (boots to game) | [→](https://github.com/einky/buildroot_os) |
| [runtime](https://github.com/einky/runtime) | Frame pipeline + input + SPI driver + ESP32 dev bridge (canonical owner) | [→](https://github.com/einky/runtime) |
| [launcher](https://github.com/einky/launcher) | Ren'Py game selector shown at boot | [→](https://github.com/einky/launcher) |
| [server](https://github.com/einky/server) | FastAPI backend | [→](https://github.com/einky/server) |
| [web](https://github.com/einky/web) | Web frontend | [→](https://github.com/einky/web) |
| [case](https://github.com/einky/case) | Enclosure / hardware design | [→](https://github.com/einky/case) |
| [games](https://github.com/einky/games) | Ren'Py game sources | [→](https://github.com/einky/games) |
| ~~os~~ | **Archived** — pi-gen image build, replaced by `buildroot_os` ([ADR 0007](./adr/0007-buildroot-os.md)) | — |

## Prerequisites

- `git` (≥ 2.30)
- `bash` (≥ 4)
- `curl`, `tar`, `sha256sum`
- `docker` and `docker compose` (for the local dev stack and the `buildroot_os` build)
- `python` 3.14 (see `versions.env`)
- An SSH key registered with GitHub, if you plan to use `--ssh`

## Bootstrap workflow

```bash
git clone https://github.com/einky/meta.git
cd meta
./bootstrap.sh                # https (default)
./bootstrap.sh --ssh          # ssh remotes instead
```

The script clones each sibling repo into `..` next to `meta/`. It is
idempotent — already-cloned repos are skipped — and prints a summary of what
was cloned, skipped, or failed. (`buildroot_os` vendors Buildroot as a
submodule — after cloning it, run `git -C ../buildroot_os submodule update
--init --recursive`.)

## Shared contract (`shared/`)

[`shared/`](./shared/) is the cross-repo source of truth for everything that was
previously duplicated across repos: panel geometry, the GPIO/SPI pin map, the
button→key/event bindings, and the wire protocols
([`shared/hardware.toml`](./shared/hardware.toml),
[`shared/protocol.md`](./shared/protocol.md)). Repos derive their constants from
it — they do not fork these values. See
[ADR 0008](./adr/0008-shared-hardware-contract.md).

## Cross-repo pinned versions

All shared version pins live in [`versions.env`](./versions.env) — the single
source of truth. Other repos source this file (or symlink to it) so a single
bump propagates everywhere; `buildroot_os` mirrors the engine/toolchain pins in
its Buildroot packages under a CI parity check.

## Installing the Ren'Py SDK (dev workstations)

```bash
./scripts/install-renpy-sdk.sh ~/renpy   # pinned version + SHA256 from versions.env
```

This is the **one** SDK installer (ADR 0004). `runtime/scripts/` symlinks it.

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
