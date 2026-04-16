---
title: AGENTS.md — get-bashed
updated: 2026-04-15
status: current
---

# get-bashed — Extended AI Protocols

This file extends `CLAUDE.md` with repository-specific architecture and operational expectations for agents.

## Architecture overview

get-bashed has two layers:

### Installer layer

- `install.sh` is POSIX `sh` only.
- It locates or installs Bash 4+ and then execs `install.bash`.
- `docs/public/install.sh` is the release-surface bootstrap served from the docs site root; it downloads a published bundle and then execs the bundled `install.sh`.
- `install.bash` is a small orchestrator that sources `installlib/*.sh` for argument parsing, profile/feature resolution, interactive UI, managed-file sync, config generation, and installer execution.

### Runtime layer

- `bashrc` is the interactive entrypoint.
- `bash_profile` is the login entrypoint and delegates to `bashrc`.
- `bashrc.d/` contains ordered modules. Local secrets live in `~/.get-bashed/secrets.d`.

### Installer helpers

- `installers/tools.sh` is the tool registry.
- `installers/sources.sh` is the shared pinned manifest for git/curl fallbacks, BATS helper refs, and built-in `asdf` runtime defaults.
- `installers/_helpers.sh` sources `installers/lib/*.sh`, which contain the helper implementations.
- Release packaging lives under `scripts/build_release_artifact.sh`, `scripts/release_validate.sh`, `scripts/publish_draft_release.sh`, `scripts/generate_pkg_manifests.sh`, and `scripts/publish_pkg_pr.sh`.
- Branch-protection verification lives in `scripts/verify_branch_protection.sh`.
- Supply-chain verification lives in `scripts/supply_chain_verify.sh`.

## Product contract

- The docs are the contract. When behavior and docs drift, prefer fixing behavior unless the current behavior is intentionally safer.
- `--dry-run` is zero-write.
- `--force` may remove stale repo-managed assets, but must never delete unknown user-owned files under the managed prefix.
- `doppler_env` is explicit integration only. Startup never auto-fetches Doppler secrets.
- `asdf` must work for both Homebrew and git installs.

## Workflow map

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | PR + push main | Ubuntu/macOS matrix quality job plus dedicated Ubuntu-under-WSL validation on `windows-2025` |
| `codeql.yml` | PR + push main + weekly schedule | Repo-owned advanced CodeQL analysis for `actions` and `python` |
| `cd.yml` | push main | Release Please, draft-first release publication, and docs build/GitHub Pages deploy |
| `release.yml` | manual dispatch | Manual recovery path for the checked-in draft-first release pipeline |
| `scorecard.yml` | push main + weekly schedule | Run OpenSSF Scorecard with the isolated permissions it needs for published results |
| `automerge.yml` | Dependabot and labeled PR events | Auto-merge approved dependency bumps |

## Agent rules

- Keep `install.sh` POSIX compatible.
- Keep every runtime module idempotent.
- Do not add secret-provider auto-sourcing on shell startup.
- Prefer updating generated docs through `scripts/gen-docs.sh` rather than hand-editing generated files.
- Treat installer, PATH, secrets, and external download changes as security-sensitive.
