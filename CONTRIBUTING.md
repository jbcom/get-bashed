# Contributing

Thanks for helping improve get-bashed. This repo is intentionally shell-first, portable, and designed to be easy to reason about.

## Project Layout

- `bashrc` and `bash_profile` are the entrypoints.
- `bashrc.d/` contains ordered runtime modules.
- `install.sh` is the installer and config generator.
- `installers/` holds dependency-aware installers and helpers.
- `scripts/` includes CI and doc helpers.
- `tests/` contains Bats tests and helper libraries.

## Local Setup

```bash
make docs
make lint
make test
```

## Pre-commit

```bash
pre-commit install
pre-commit run --all-files
```

## Tests

```bash
./scripts/test-setup.sh
bats tests
```

## Docs

```bash
./scripts/gen-docs.sh
```

## CI

CI bootstraps tools into `GET_BASHED_HOME` via `scripts/ci-setup.sh`.

## Style Guidelines

- Prefer POSIX shell in `install.sh` bootstrap and Bash elsewhere.
- Keep modules idempotent and safe to source repeatedly.
- Avoid hardcoding user paths. Use `$HOME` and `$GET_BASHED_HOME`.
- Add shdoc annotations for public functions and new scripts.

## Design Principles

- Make defaults safe and predictable.
- Keep installers minimal and dependency-light.
- Prefer explicit opt-in for any behavior that modifies user files.

## Adding a Module

1. Add a new `bashrc.d/NN-name.sh` file.
2. Keep modules idempotent and avoid side effects on import.
3. Document any new env vars in `TOOLS.md` or `README.md`.
4. Add shdoc annotations if the module exports functions.

## Adding an Installer

1. Register tools in `installers/tools.sh`.
2. Use `dependencies` and `optional_dependencies` to express ordering.
3. Avoid unpinned downloads; prefer package managers when possible.
4. If a new tool needs a custom handler, add it to `installers/_helpers.sh`.

## Docs Expectations

- Run `./scripts/gen-docs.sh` after changing scripts.
- Ensure shdoc annotations are present for new functions.
- Keep README user-focused and link to docs for deeper details.

## Pull Requests

- Keep PRs focused and small where possible.
- Include a clear summary and testing notes.
- Update docs when behavior changes.
- Avoid adding unpinned dependencies or unverified downloads.

## Conventional Commits

PR titles must follow Conventional Commits, for example `feat: add installer`.

## Security

Security-sensitive changes (installers, PATH, secrets) require extra scrutiny. See `SECURITY.md` for reporting guidance.

## Branch Protection

See `docs/CONFIG.md` for recommended required checks and CODEOWNERS review.
