---
title: Release Checklist
updated: 2026-04-15
status: current
---

# Release Checklist

Use this checklist before and after cutting a release from `main`.

## Before Tagging

1. Confirm `main` branch protection still requires the live CI job contexts and code owner review.

   ```bash
   make verify-branch-protection
   ```

   If `.github/workflows/codeql.yml` is already on `main`, this check also expects `CodeQL (actions)` and `CodeQL (python)` to be required.

   If `codeql.yml` has just landed on `main` and live GitHub is still on default setup, run:

   ```bash
   make reconcile-codeql-governance
   ```

2. Confirm the live immutable-release posture is either already enabled or still correctly deferred until the draft-first workflow lands on `main`.

   ```bash
   make verify-immutable-release-governance
   ```

   If the draft-first workflow has just landed on `main` and GitHub immutable releases are still off, run:

   ```bash
   make reconcile-immutable-release-governance
   ```

3. Run the merge-equivalent quality gates.

   ```bash
   make ci
   ```

4. Exercise the checked-in release packaging path.

   ```bash
   make smoke-release
   make release-validate
   ```

5. If you are validating an already-published tag, verify the public release surface directly.

   ```bash
   make verify-published-release TAG=v0.1.0
   ```

6. Confirm the docs/download surface still points at the release bundles and package-manager channels, and that outbound docs links still pass.

7. Confirm `jbcom/pkgs` is ready to accept the generated Homebrew, Scoop, and Chocolatey manifest PR.

## After Publishing

1. Verify that the release was published from a draft and now contains `get-bashed-<version>-unix.tar.gz`, `get-bashed-<version>-windows.zip`, and `checksums.txt`.
2. Verify that published checksums match the uploaded assets.
3. Verify GitHub attestation for at least one downloaded asset.
4. If immutable releases are enabled live, confirm the release is marked immutable.
5. Confirm the docs-site `install.sh` still installs the just-published release.
6. Confirm the package PR against `jbcom/pkgs` was created and queued for merge.
