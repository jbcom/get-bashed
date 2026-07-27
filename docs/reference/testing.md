---
title: Testing
updated: 2026-04-15
status: current
---

# Testing

Local quality gates:

```bash
make lint
make test
make docs
make docs-check
make verify-security
make verify-branch-protection
```

Release-oriented validation adds:

```bash
make package-release
make smoke-release
make release-validate
make verify-published-release TAG=v0.1.0
```

CI validates the repo on:

- `ubuntu-latest`
- `macos-latest`
- Ubuntu under WSL on `windows-2025`

The Ubuntu and macOS entries also run the checked-in supply-chain verifier.

For the deeper test matrix and runtime-module coverage notes, see [TESTING.md](../TESTING.md).
