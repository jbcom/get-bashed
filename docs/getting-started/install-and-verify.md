---
title: Install And Verify
updated: 2026-04-15
status: current
---

# Install And Verify

## Install The Latest Release

```bash
curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh
```

Pin a specific release tag:

```bash
curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh -s -- --version v0.1.0
curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh -s -- --version 0.1.0
```

Pass normal installer flags straight through to the bundled installer:

```bash
curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh -s -- --profiles dev --link-dotfiles
curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh -s -- --auto --prefix "$HOME/.get-bashed"
```

## Install From A Downloaded Bundle

```bash
curl -LO https://github.com/jbcom/get-bashed/releases/download/v0.1.0/get-bashed-0.1.0-unix.tar.gz
tar -xzf get-bashed-0.1.0-unix.tar.gz
cd get-bashed-0.1.0-unix
sh install.sh --profiles dev --link-dotfiles
```

## Verify The Result

Confirm the managed prefix exists:

```bash
test -f "$HOME/.get-bashed/get-bashedrc.sh"
test -d "$HOME/.get-bashed/bashrc.d"
```

If you linked dotfiles, confirm the startup entrypoints point at the managed tree:

```bash
ls -l "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.gitconfig" "$HOME/.vimrc"
```

If you are validating a checkout instead of a published release, the repo-owned smoke path is still:

```bash
make test
./scripts/verify-install.sh
```
