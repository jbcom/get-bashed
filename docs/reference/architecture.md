---
title: Architecture
updated: 2026-04-15
status: current
---

# Architecture

The product still has two layers:

- the POSIX bootstrap in `install.sh`
- the managed runtime tree rooted at `bashrc`, `bash_profile`, and `bashrc.d/`

The installer/bootstrap contract is now also part of the public release surface:

- the repo-root `install.sh` is the source-tree bootstrap
- the docs-site `/install.sh` is the published release bootstrap
- the release archives embed the full installer/runtime tree and are validated before publication

For the full architecture walkthrough, including module loading and installer helper layout, see the source-tree reference page: [ARCHITECTURE.md](../ARCHITECTURE.md).
