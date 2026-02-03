# Progress

## What works
- Installer framework with profiles/features/installers
- Memory bank + docs pipeline
- CI workflows and release automation
- Pre-commit policy and security docs
- Centralized tools registry + handlers
- Dotfile linking with backups + defaults
- Git identity prompts + config output
- Optional dependency gating by feature flags

## What's left
- CI green after bashate/shellcheck changes
- Expand BATS coverage to core flows
- Document tool registry and optional deps in README

## Known issues
- shdoc not available via Homebrew on macOS; uses local prefix install.
- Ensure docs generation uses `GET_BASHED_HOME/bin` shdoc in CI.
