---
title: TESTING.md — get-bashed
updated: 2026-04-15
status: current
---

# Testing

## Strategy

The test suite covers installer semantics, runtime behavior, docs contract drift, and install verification.

## Commands

```bash
make lint
make test
make docs
make docs-check
make verify-security
make verify-branch-protection
make verify-immutable-release-governance
make reconcile-codeql-governance
make reconcile-immutable-release-governance
make package-release
make smoke-release
make release-validate
```

`make test` runs:

1. `source ./scripts/ci-setup.sh "bats"`
2. `./scripts/test-setup.sh`
3. `bats tests`
4. `./scripts/verify-install.sh`

The BATS suite resolves a Bash 4+ interpreter at runtime instead of assuming a macOS Homebrew path, so the same tests run against the Ubuntu and macOS CI matrix entries and the Ubuntu-under-WSL validation job.
Direct ad hoc runs such as `bats tests/runtime_modules.bats` also self-bootstrap the pinned helper libraries through `tests/test_helper.bash` when `tests/lib/` is missing.

`make docs` runs:

1. `source ./scripts/ci-setup.sh "shdoc,uv"`
2. `./scripts/gen-docs.sh`
3. `./scripts/validate-docs.sh`
4. `uvx tox -e docs`

The docs targets now bootstrap both `shdoc` and `uv` so `uvx` is available even on a machine that does not already have it on `PATH`.
`make docs-check` runs the same docs generation path and then adds `uvx tox -e docs,docs-linkcheck`.

`make verify-security` runs the repo-owned supply-chain verifier across workflow SHA pinning, the checked-in `codeql.yml` and `scorecard.yml` workflows, pinned installer download sources, Dependabot/security-fix posture, secret scanning posture, draft-first release publication wiring, immutable-release governance, docs-link wiring, and branch-protection verification availability. Once `codeql.yml` lands on `main`, that same verifier expects GitHub default CodeQL setup to be turned off.

`make release-validate` builds the Unix and Windows release bundles, validates their checksums and archive contents, generates the Homebrew/Scoop/Chocolatey manifests, and exercises `docs/public/install.sh` against a local HTTP server backed by the built release archives. The release-pipeline BATS coverage separately forces the installer through its supported `wget` fallback path so the non-default downloader surface also stays exercised.

`make verify-branch-protection` is a separate authenticated governance check. It uses `gh api` to verify that GitHub branch protection for `main` still requires the exact CI job names this repo depends on and still enforces the expected review, code owner, and branch-safety settings.
`make reconcile-codeql-governance` is the one-time authenticated cutover for moving live `main` from GitHub default CodeQL setup to the checked-in `.github/workflows/codeql.yml` path once that workflow has landed on `main`.
`make verify-immutable-release-governance` is the parallel live check for releases. It defers until the checked-in draft-first release flow is present on `main`, and after that it expects GitHub immutable releases to be enabled.
`make reconcile-immutable-release-governance` is the one-time authenticated cutover for enabling GitHub immutable releases after the checked-in draft-first flow has landed on `main`.

## BATS coverage

The suite currently covers:

- installer config output and escaping
- bootstrap selection behavior
- true dry-run behavior
- link-dotfiles behavior and backups
- manifest-based force behavior for managed assets
- optional dependency resolution
- runtime module behavior for Doppler and asdf
- pinned `asdf` runtime selection
- legacy migration safety
- documentation contract checks
- branch-protection verifier behavior
- supply-chain verifier behavior
- release bundle and package-manifest validation
- immutable-release governance verification and cutover
- docs-site installer fallback downloader coverage

## CI coverage

`ci.yml` runs the full quality pipeline on:

- `ubuntu-latest`
- `macos-latest`

It also runs a dedicated WSL validation job on:

- `windows-2025`, booting Ubuntu under WSL for lint, BATS, and install verification

The Ubuntu and macOS matrix entries run lint, BATS, install verification, docs generation, docs build, Sphinx link checking, and the repo-owned supply-chain verifier from a clean checkout. The WSL job reuses the repo `make lint` and `make test` targets inside Ubuntu under WSL so the Windows-hosted Linux path is exercised directly.
Separately, `.github/workflows/codeql.yml` runs repo-owned advanced CodeQL analysis for `actions` and `python` on PRs, on `main`, and on the weekly schedule.

## Helper libraries

`scripts/test-setup.sh` fetches pinned BATS helper libraries into `tests/lib/` using refs from `installers/sources.sh`. If a library directory already exists without git metadata, with the wrong remote, or at the wrong commit, the script replaces it so repeated runs stay deterministic.

## Remaining gaps

- Optional startup behaviors still need periodic review for latency and predictability.
