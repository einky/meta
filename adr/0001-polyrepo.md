# ADR 0001: Polyrepo layout

- Status: Accepted
- Date: 2026-05-08

## Context

Crab-Ink-Gaming spans several distinct domains: a Raspberry Pi OS image, an
on-device Python runtime, a Ren'Py-based launcher, individual Ren'Py games, a
FastAPI server, a web admin UI, and hardware case design. Each has its own
toolchain, release cadence, dependency set, and reviewer set. We considered
both a single monorepo and a polyrepo with a workspace bootstrapper.

Constraints:

- Per-repo CI must stay simple and fast — `os` builds a multi-GB image, while
  `web` is a small Node project.
- External contributors should be able to engage with one component (e.g. add
  a game in `games`) without cloning the whole world.
- We do not have a monorepo build system (Bazel, Nx, etc.) and don't want to
  introduce one yet.

## Decision

Use a polyrepo layout under the `Crab-Ink-Gaming` GitHub org. The `meta` repo
is the workspace entry point: it carries the bootstrap script, ADRs, shared
scripts, the local dev compose stack, and the cross-repo `versions.env` file.
`bootstrap.sh` clones every other repo into `..` so they sit as siblings.

## Consequences

- Each repo has its own issues, releases, CI, and CODEOWNERS — clean
  ownership boundaries.
- Cross-cutting changes touch multiple PRs across repos. We accept that cost
  and mitigate it by keeping interfaces narrow and documented in `docs/`.
- Version skew between repos is possible. `versions.env` is the single source
  of truth for shared pins, sourced (or symlinked) by downstream scripts.
- New contributors run two commands (`git clone meta && ./bootstrap.sh`)
  instead of one. The README must keep this path obvious.
