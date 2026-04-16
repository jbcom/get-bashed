---
title: CONFIG.md — get-bashed
updated: 2026-04-15
status: current
---

# Configuration

get-bashed writes a generated runtime config at:

```bash
~/.get-bashed/get-bashedrc.sh
```

The file is written by the installer and sourced by `bashrc` on startup.

## Keys

Always emitted:

- `GET_BASHED_GNU`
- `GET_BASHED_BUILD_FLAGS`
- `GET_BASHED_AUTO_TOOLS`
- `GET_BASHED_SSH_AGENT`
- `GET_BASHED_USE_DOPPLER`
- `GET_BASHED_USE_BASH_IT`
- `GET_BASHED_GIT_SIGNING`
- `GET_BASHED_VIMRC_MODE`

Conditionally emitted:

- `GET_BASHED_USER_NAME`
- `GET_BASHED_USER_EMAIL`

## Prefix

Set `GET_BASHED_HOME` to override the managed install prefix for the installer and runtime.

Example:

```bash
export GET_BASHED_HOME="$RUNNER_TEMP/get-bashed"
./install.sh --auto --install shdoc
```

## Profiles

- `minimal`: all flags off, no installers.
- `dev`: GNU tools, build flags, auto tools.
- `ops`: `dev` plus SSH agent and explicit Doppler support.

Profiles live in `profiles/*.env` and may define both `FEATURES` and `INSTALLS`.

## Feature bundles

These feature names expand into installer lists:

- `dev_tools`
- `ops_tools`

## Branch protection

Current `main` branch protection policy:

- `Quality (ubuntu-latest)`
- `Quality (macos-latest)`
- `Quality (wsl-ubuntu)`
- `SonarQube Scan`
- strict status checks enabled
- 1 approving review required
- stale reviews dismissed on new pushes
- code owner reviews required
- admin enforcement enabled
- linear history required
- conversation resolution required

`cd.yml`, `release.yml`, and `scorecard.yml` are intentionally not required branch checks because they do not run as PR validation jobs. The checked-in verifier for this policy is:

```bash
make verify-branch-protection
```

After `.github/workflows/codeql.yml` lands on `main` and GitHub default CodeQL setup is retired, `make verify-branch-protection` also expects `CodeQL (actions)` and `CodeQL (python)` to become required checks.

`CODEOWNERS` is active policy, not a placeholder: the repository requires code owner review on `main`.
