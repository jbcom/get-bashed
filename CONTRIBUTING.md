# Contributing

Thanks for helping improve get-bashed.

## Architecture

- `bashrc` / `bash_profile` are the entrypoints.
- `bashrc.d/` is the ordered module system.
- `install.sh` is the installer and config generator.
- `installers/` contains dependency-aware installers.
- `scripts/` holds CI and doc helpers.

## Development

```bash
make docs
make lint
```

## Pre-commit

Install hooks:
```bash
pre-commit install
```

Run all checks:
```bash
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

CI uses `scripts/ci-setup.sh` to bootstrap tools into `GET_BASHED_HOME`.

## Guidelines

- Keep scripts portable and dependency-light.
- Avoid hardcoding user-specific paths.
- Add shdoc annotations for new scripts.

## Conventional Commits

PR titles must follow Conventional Commits (e.g., `feat: add installer`).

## Branch Protection

See `docs/CONFIG.md` for recommended required checks and CODEOWNERS review.
