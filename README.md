# get-bashed

[![CI](https://github.com/jbcom/get-bashed/actions/workflows/ci.yml/badge.svg)](https://github.com/jbcom/get-bashed/actions/workflows/ci.yml)
[![Docs](https://github.com/jbcom/get-bashed/actions/workflows/docs.yml/badge.svg)](https://github.com/jbcom/get-bashed/actions/workflows/docs.yml)
[![Release](https://github.com/jbcom/get-bashed/actions/workflows/release-please.yml/badge.svg)](https://github.com/jbcom/get-bashed/actions/workflows/release-please.yml)

A modern, modular Bash environment you can install anywhere. get-bashed is designed to be readable, portable, and safe to extend, with a clean installer that supports interactive and non-interactive setups.

## Why get-bashed

- Modular `bashrc.d` architecture
- Cross-platform defaults (macOS, Linux, WSL)
- Optional GNU tooling on macOS
- Reproducible installs with profiles and features
- Safe secrets handling via `secrets.d`

## Quick Start

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/jbcom/get-bashed/main/install.sh
# Review install.sh before running
sh install.sh
```

## Learn More

Docs: `https://jonbogaty.com/get-bashed`

## Features

Use `--features` with comma lists (supports `no-` prefix):
- `gnu_over_bsd`
- `build_flags`
- `auto_tools`
- `ssh_agent`
- `doppler_env`
- `dev_tools` (bundle)
- `ops_tools` (bundle)

## Installers

Available installers (comma list):
- `brew`, `asdf`, `doppler`, `dialog`, `starship`, `direnv`, `gnu_tools`
- `git`, `curl`, `wget`, `gnupg`
- `rg`, `fd`, `bat`, `fzf`, `jq`, `yq`, `tree`
- `gh`, `git_lfs`, `terraform`, `awscli`, `kubectl`, `helm`, `stern`
- `nodejs`, `python`, `java`
- `pipx`, `pre_commit`, `bashate`, `shellcheck`, `actionlint`, `bats`, `shdoc`, `bash`
- `bash_it` (bash-it framework)
- `vimrc` (amix/vimrc)

## Support

- Issues and feature requests: use GitHub Issues for this repository.
- Security: see `SECURITY.md`.
- Contributing: see `CONTRIBUTING.md`.
