---
title: CONFIG.md — get-bashed
updated: 2026-04-10
status: current
---

# Configuration

get-bashed writes a generated config file at:

```
~/.get-bashed/get-bashedrc.sh
```

This file contains the resolved configuration from the installer and is sourced by the runtime. You can edit it manually after install if desired.

## Keys

- `GET_BASHED_GNU` (0/1)
- `GET_BASHED_BUILD_FLAGS` (0/1)
- `GET_BASHED_AUTO_TOOLS` (0/1)
- `GET_BASHED_SSH_AGENT` (0/1)
- `GET_BASHED_USE_DOPPLER` (0/1)

## Feature Bundles

These are feature keywords that expand to installer sets:
- `dev_tools`
- `ops_tools`

## Defaults

If you run the installer with no flags, the defaults are conservative:

- GNU tools: off
- Build flags: off
- Auto tools: off
- SSH agent: off
- Doppler: off

These defaults are written into `get-bashedrc.sh` so installs are reproducible.

## Override Install Prefix

Set `GET_BASHED_HOME` to override the install prefix (used by the installer and runtime).
Example for CI:

```bash
export GET_BASHED_HOME=\"$RUNNER_TEMP/get-bashed\"
./install.sh --auto --install shdoc
```

## Profiles

- `minimal`: all flags off.
- `dev`: `GET_BASHED_GNU=1`, `GET_BASHED_BUILD_FLAGS=1`, `GET_BASHED_AUTO_TOOLS=1`.
- `ops`: `dev` plus `GET_BASHED_SSH_AGENT=1` and `GET_BASHED_USE_DOPPLER=1`.

Profiles live in `profiles/*.env` and can include both `FEATURES` and `INSTALLS`.


## Branch Protection

Recommended required checks:
- CI workflow (`ci.yml`)
- PR title lint (`pr-title.yml`)
- Docs build (`docs.yml`) if you publish Pages

Also consider requiring CODEOWNERS review.
