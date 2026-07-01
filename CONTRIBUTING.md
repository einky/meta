# Contributing

Thanks for working on Einky. These conventions apply to every repo
in the org unless that repo's own `CONTRIBUTING.md` overrides them.

## Branches

Branch names are `<type>/<short-slug>`:

- `feat/` — new user-visible functionality
- `fix/`  — bug fix
- `chore/` — tooling, deps, refactors with no behavior change
- `docs/` — documentation only
- `adr/`  — adding or amending an ADR

Examples: `feat/launcher-controller-input`, `fix/server-telemetry-retry`,
`chore/bump-renpy-sdk`.

Branch off `main`. Rebase, don't merge, before opening the PR.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

- `type` — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `build`,
  `ci`, `perf`.
- `scope` — optional, the area touched (e.g. `launcher`, `os`, `catalog`).
- `subject` — imperative, lowercase, no trailing period.
- Breaking changes get a `!` after the type/scope (`feat(api)!: ...`) and a
  `BREAKING CHANGE:` footer explaining the migration.

One logical change per commit. Squash fixups before review.

## Pull requests

- Title follows the same Conventional Commits format as commits.
- Description must cover **what changed**, **why**, and **how it was
  tested**. For UI changes attach a screenshot or recording.
- Link the issue (`Closes #123`) when one exists.
- Keep PRs small. If a PR is touching more than ~400 lines or more than one
  concern, split it.
- CI must be green before review.
- At least one approving review from a CODEOWNER of the touched paths.
  Author cannot self-approve.
- Squash-merge by default. The squash commit message must remain a valid
  Conventional Commit.

## DCO

We use the [Developer Certificate of Origin](https://developercertificate.org/).
Sign every commit with `git commit -s` — this appends a `Signed-off-by:`
trailer asserting you have the right to contribute the change. PRs with
unsigned commits will be asked to amend or rebase with `-s`.

We do not require a CLA.

## Cross-repo changes

A change touching multiple repos (e.g. an API contract update in `server`
that `runtime` and `web` consume) opens one PR per repo. Cross-link them in
each PR description and merge in dependency order: producer first, then
consumers. Note any required `versions.env` bump in `meta`.

## Code of conduct

Be kind. Disagree on technical grounds, not personal ones. Maintainers may
close or lock threads that drift from that standard.
