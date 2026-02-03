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
