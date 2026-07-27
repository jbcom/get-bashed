---
title: README.md — get-bashed
updated: 2026-04-15
status: current
---

# Docs Pipeline

`scripts/gen-docs.sh` generates the installer-facing reference docs.
The installer registry and pinned source/runtime manifest live in `installers/tools.sh`
and `installers/sources.sh`.

## Generated docs

- `docs/INSTALLER.md`
- `docs/INSTALLERS_HELPERS.md`
- `docs/INSTALLERS.md`

## Manual docs

- `docs/getting-started/`
- `docs/reference/`
- `docs/api/index.md`
- `docs/public/install.sh`
- `docs/MODULES.md`
- `docs/CONFIG.md`
- `docs/STATE.md`
- `docs/TESTING.md`
- `docs/ARCHITECTURE.md`
- `docs/DESIGN.md`
- `docs/SHDOC.md`
- `docs/index.md`
- `docs/reference/security.md`

## Commands

```bash
make docs
make docs-check
make verify-security
./scripts/validate-docs.sh
```

`make docs` bootstraps `shdoc` and `uv` through `scripts/ci-setup.sh`, regenerates the shell reference docs, validates the docs contract, and builds the Sphinx site.
`make docs-check` runs the same generation path and then adds Sphinx link checking for outbound docs links.
`make verify-security` runs the checked-in supply-chain verifier that checks workflow pinning, repo-owned CodeQL/Scorecard presence, pinned installer sources, draft-first release/publication wiring, immutable-release governance, Dependabot/security-fix posture, docs-link wiring, and branch-protection verification availability.

## CI and publishing

- `ci.yml` validates docs generation, the Sphinx build, and outbound docs links on Ubuntu and macOS.
- `cd.yml` rebuilds docs on `main`, creates the draft GitHub release, validates and publishes the checked-in release bundles, and then publishes GitHub Pages.
- `release.yml` is the manual recovery workflow for rerunning the same draft-first release pipeline against an existing draft tag.
- `scorecard.yml` runs a separate OpenSSF Scorecard analysis because Pages deploy and release workflows need different permissions.
- `codeql.yml` runs repo-owned advanced CodeQL analysis for `actions` and `python`.
- `scripts/verify_branch_protection.sh` plus `make verify-branch-protection` check the live `main` branch required status contexts when `gh` auth is available.
- `scripts/verify_immutable_release_governance.sh` plus `make verify-immutable-release-governance` check the live immutable-release posture when `gh` auth is available.
- `scripts/ci-setup.sh` persists `GET_BASHED_HOME` and `PATH` through GitHub Actions step boundaries using `GITHUB_ENV` and `GITHUB_PATH`.
