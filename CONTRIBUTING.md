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
