---
title: Security Policy
updated: 2026-04-09
status: current
domain: technical
---

# Security Policy

This project prioritizes safe defaults, explicit install paths, and minimal privilege. Please help keep it secure by reporting issues responsibly.

## Supported Versions

- Only the latest release receives security updates.
- The `main` branch may include fixes before the next release.

## Reporting a Vulnerability

- Use GitHub Security Advisories for private reporting.
- If you cannot use GitHub, open a private discussion with the maintainer via GitHub.
- Do not open a public issue for security reports.

## What to Include

- A clear description of the issue and impact.
- Steps to reproduce, including relevant commands or configs.
- Affected versions or commit SHAs.
- Any known mitigations or workarounds.

## Response Expectations

- Acknowledgement within 3 business days.
- Initial triage within 7 business days.
- Fix and disclosure timeline will be shared after confirmation.

## Disclosure

- Coordinated disclosure is expected.
- Please avoid publishing proof-of-concepts until a fix is released.

## Scope Notes

- `install.sh` and scripts in `installers/` are security-sensitive.
- Any `curl` or `git` installation path must be verified and pinned when feasible.
- Changes that modify PATH, shell startup, or secret handling are in scope.

## Threat Model (Summary)

### Assets

- User secrets in `secrets.d/` and any injected environment variables.
- Shell startup integrity (`bashrc`, `bash_profile`, `bashrc.d/`).
- Installer integrity (`install.sh`, `installers/`, `scripts/ci-setup.sh`).
- User PATH and toolchain selection (asdf/brew/system).

### Adversaries

- Supply-chain tampering (compromised GitHub releases, mirrors, or plugins).
- Local adversary modifying `~/.get-bashed` or symlinked dotfiles.
- Malicious PRs introducing unsafe shell behavior.

### Common Risks

- Unpinned downloads or unverified `curl`/`git` installers.
- Command injection via untrusted input in shell scripts.
- PATH poisoning via incorrect ordering or untrusted directories.
- Secrets leakage via logs or generated config files.

### In-Scope Surfaces

- Installer inputs, profiles, and feature handling.
- Tool registry definitions and dependency ordering.
- Any code touching secrets, PATH, or shell init files.

### Out of Scope

- Upstream security issues in third-party tools (report to upstream).
- User-specific misconfiguration outside of get-bashed artifacts.

## Hardening Expectations

- Avoid `eval` and unsafe command substitutions.
- Validate all user input that affects execution paths.
- Prefer pinned versions and checksums where feasible.
- Keep idempotency to avoid repeated side effects.
