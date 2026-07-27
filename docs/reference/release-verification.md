---
title: Release Verification
updated: 2026-04-15
status: current
---

# Release Verification

## Local Emulation

Use the checked-in release scripts before tagging:

```bash
make verify-branch-protection
make package-release
make smoke-release
make release-validate
```

`make verify-branch-protection` catches stale GitHub required-check policy before it blocks or silently weakens the release line.
`make verify-immutable-release-governance` catches drift in the live immutable-release posture once the checked-in draft-first workflow has landed on `main`.

`make package-release` creates the Unix and Windows bundles under `dist/release/`.

`make smoke-release` checks the Unix installer path plus the Windows wrapper bundle structure.

`make release-validate` verifies the archive checksums, generated package manifests, and the docs-site `install.sh` path against a local HTTP server backed by the built artifacts. The release-pipeline BATS suite separately forces the installer through the supported `wget` fallback path so the documented downloader surface stays real without making the checked-in release validator depend on a downloader shim.
The checked-in GitHub workflow follows the same draft-first order GitHub recommends for immutable releases: create a draft, attach the validated assets, then publish it.

## Verify A Published Release

If the tag is already published:

```bash
make verify-published-release TAG=v0.1.0
```

That script verifies:

- the release is no longer a draft
- the exact expected asset set
- checksum integrity for the downloaded host-native asset
- GitHub attestation for the downloaded asset
- the smoke path through `scripts/smoke_test_release_artifact.sh`

## Re-run Manifest Generation

If you have a complete local release dist directory:

```bash
bash scripts/generate_pkg_manifests.sh 0.1.0 dist/release/checksums.txt dist/release/pkg
```

That reproduces the Homebrew, Scoop, and Chocolatey metadata that the release workflow publishes into `jbcom/pkgs`.
