# Docs Pipeline

This repo uses `shdoc` to generate documentation from shell scripts.

## Generate

```bash
./scripts/gen-docs.sh
```

Outputs:
- `docs/INSTALLER.md`
- `docs/INSTALLERS_HELPERS.md`
- `docs/INSTALLERS.md`
- `docs/MODULES.md`
- `docs/INDEX.md`

## GitHub Pages

The `docs.yml` workflow builds and publishes `docs/` to GitHub Pages. The entry
page is `docs/index.md`.

## CI Setup

CI uses `scripts/ci-setup.sh` to install tools into `GET_BASHED_HOME` (defaults
to `RUNNER_TEMP` on GitHub Actions).
