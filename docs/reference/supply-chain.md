---
title: Supply Chain
updated: 2026-04-15
status: current
---

# Supply Chain

`get-bashed` is intentionally pinned at every external boundary that it controls:

- bootstrap Homebrew download sources and SHA-256 checksums live in `installers/bootstrap_sources.sh`
- git and curl fallbacks live in `installers/sources.sh`
- `asdf` default runtime versions are pinned in `installers/sources.sh`
- release packaging is driven by checked-in scripts rather than ad hoc archive commands
- release publication follows the draft-first flow required by GitHub immutable releases
- package-manager manifests are generated from `checksums.txt`, not by hand
- Dependabot policy is tracked in `.github/dependabot.yml`
- advanced CodeQL analysis is tracked in `.github/workflows/codeql.yml`, not left as an invisible GitHub default-setup toggle
- every GitHub Actions workflow starts from explicit top-level `permissions: {}` and only opts into write scopes at the job level

The release workflow validates:

- archive contents
- checksum integrity
- docs-site installer behavior
- generated Homebrew, Scoop, and Chocolatey manifests
- draft-release upload and publish ordering
- published release asset shape before opening a PR against `jbcom/pkgs`

The repository also runs a separate `scorecard.yml` workflow so OpenSSF Scorecard can publish results without conflicting with the Pages and release workflows' broader permissions.
The live GitHub branch-protection policy is checked by `scripts/verify_branch_protection.sh` and exposed as `make verify-branch-protection`, because required status contexts, review requirements, and branch-safety flags live in GitHub configuration rather than the Git tree.
The broader repository-owned supply-chain gate lives in `scripts/supply_chain_verify.sh` and is exposed as `make verify-security`.
Once `codeql.yml` lands on `main`, that supply-chain verifier also expects GitHub default CodeQL setup to be disabled and the repo-owned workflow to take over fully.
The one-time cutover is scripted in `scripts/reconcile_codeql_governance.sh` and exposed as `make reconcile-codeql-governance`.
Live GitHub vulnerability alerts and automated Dependabot security fixes are also part of that verified production posture when `gh` auth is available.
So are live secret scanning, push protection, validity checks, and non-provider secret patterns.
The immutable-release cutover is handled the same way: `scripts/verify_immutable_release_governance.sh` and `make verify-immutable-release-governance` verify the live posture, and `scripts/reconcile_immutable_release_governance.sh` plus `make reconcile-immutable-release-governance` perform the one-time enablement after the checked-in draft-first workflow lands on `main`.

For the broader runtime and secrets policy, see [Security](security.md).
