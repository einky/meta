---
sidebar_position: 1
title: 0001 — FastAPI for the server
---

# ADR 0001 — FastAPI for the server

- **Status:** Accepted
- **Date:** 2026-05-08
- **Deciders:** Inky core team

## Context

The `server` repo owns the catalog API, telemetry ingestion, and the management endpoints consumed by `web` and (read-only) by the on-device runtime. The load profile is modest: low-RPS catalog reads, batched telemetry writes, and infrequent admin mutations.

We considered four frameworks across three languages: **FastAPI** (Python), **Django** (Python), **Gin** (Go), and **Laravel** (PHP).

Constraints that mattered:

- The rest of the device-side stack is Python (runtime, frame pipeline, SDK install scripts).
- `web` consumes a typed client; we want OpenAPI generated from the source of truth, not hand-written.
- Telemetry payload shapes evolve quickly during development; cheap, validated schemas are more valuable than raw throughput.
- The team is two developers — language sprawl has a real cost.

## Decision

We will use **FastAPI** for the `server` repo.

## Consequences

**Positive**

- Pydantic models double as the wire schema and the validation layer; the same types serialize telemetry on the runtime side and validate it on the server side.
- OpenAPI is generated from the route signatures, so `web/` regenerates its TypeScript client from a single source of truth.
- Contributors move between `runtime/` and `server/` without a language switch.
- ASGI gives us async I/O for the few endpoints that fan out to Postgres + object storage, without forcing async on the rest of the codebase.

**Negative / accepted trade-offs**

- We give up Go's concurrency ceiling. Acceptable: the workload is far below where that matters.
- We give up Django's batteries (admin, ORM conventions, templating). Acceptable: the admin UI lives in `web/`, so Django's strongest features would be unused.
- We give up Laravel's ecosystem maturity. Acceptable: nobody on the team is currently shipping PHP, and adding a third language would dominate any framework-level win.

## Alternatives rejected

- **Django** — same Python win, but oriented toward server-rendered apps. The features we'd actually use overlap heavily with FastAPI; the features we wouldn't use add weight.
- **Gin** — fast and idiomatic, but introduces Go alongside Python with no payoff for our load. No ergonomic equivalent of Pydantic-driven OpenAPI.
- **Laravel** — mature, but a third language for the team and a heavier runtime than the workload justifies.
