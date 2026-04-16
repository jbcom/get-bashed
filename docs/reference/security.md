---
title: Security
updated: 2026-04-15
status: current
---

# Security

## Security-Sensitive Surfaces

The highest-risk surfaces in `get-bashed` are:

- bootstrap and installer download paths
- managed PATH construction and shell startup wiring
- explicit secrets integration points
- release bundle and package-manager publication scripts

Those surfaces are expected to stay pinned, reviewable, and covered by checked-in validation.

## Reporting

For reporting instructions, disclosure guidance, and the repository security policy, see the repository root `SECURITY.md` in the source tree and the GitHub Security policy for the repository.

## Validation Hooks

The repo’s security-oriented checks now include:

- `make lint`
- `make test`
- `make docs-check`
- `make verify-security`
- `make verify-branch-protection`
- `make verify-immutable-release-governance`
- `make reconcile-codeql-governance`
- `make reconcile-immutable-release-governance`
- `make release-validate`

`make verify-security` is the repo-owned supply-chain gate. It checks workflow SHA pinning, explicit top-level workflow permission lockdown, the repo-owned `codeql.yml` and `scorecard.yml` workflows, pinned installer download sources, checked-in Dependabot config, live vulnerability-alert/security-fix settings, secret scanning, secret scanning push protection, validity checks, non-provider secret patterns, draft-first release/publication wiring, immutable-release governance, docs-link validation wiring, and branch-protection verification availability when `gh` auth is available. Once `codeql.yml` lands on `main`, the same verifier expects GitHub default CodeQL setup to be retired in favor of the checked-in workflow.
`make verify-branch-protection` is the authenticated live-policy check for the `main` branch itself.
`make reconcile-codeql-governance` is the repo-owned post-merge cutover for that change; it retires GitHub default CodeQL setup and patches the live branch required-check list to include the repo-owned CodeQL jobs.
`make verify-immutable-release-governance` is the authenticated live-policy check for GitHub immutable releases once the draft-first release flow is on `main`.
`make reconcile-immutable-release-governance` is the repo-owned post-merge cutover for that change; it enables GitHub immutable releases after the checked-in draft-first release flow is live on `main`.
