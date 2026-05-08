# ADR 0003: FastAPI for the backend server

- Status: Accepted
- Date: 2026-05-08

## Context

The server hosts the game catalog, device registration, telemetry intake,
and the admin API consumed by `web`. We need a Python web framework because
the team's strongest language is Python and the on-device runtime is also
Python — sharing model definitions and validators between the two is
valuable.

Options considered:

1. **FastAPI** — async, Pydantic-based validation, OpenAPI generation
   built-in, strong type-checking story.
2. **Django + DRF** — batteries-included, mature admin, but heavyweight for
   what is mostly a JSON API; ORM coupling makes async harder.
3. **Flask** — minimal but every feature (validation, OpenAPI, async) is a
   third-party add-on we'd have to choose and maintain.

## Decision

Use **FastAPI** with Pydantic v2 models, SQLAlchemy 2.x async, and Alembic
for migrations. Python version is pinned in `versions.env`.

## Consequences

- Pydantic models are shared between server and runtime — a single source of
  truth for the catalog/telemetry schemas.
- OpenAPI spec is generated automatically; `web` consumes it via a generated
  client, removing a class of integration drift bugs.
- Async-everywhere requires discipline (no blocking calls in handlers). We
  document the rule and rely on linting/code review.
- Less out-of-the-box than Django: no auto-admin, no built-in auth. We build
  what we need or pull focused libraries (e.g. `fastapi-users`).
