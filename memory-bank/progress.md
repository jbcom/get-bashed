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
- POSIX bootstrap (`install.sh`) + bash installer (`install.bash`)
- Symlink-only dotfile wiring to `~/.get-bashed`
- Install verification script wired into CI

## What's left
- Confirm CI green after latest installer refactors
- Expand BATS coverage to core flows

## Known issues
- shdoc not available via Homebrew on macOS; uses local prefix install.
- Ensure docs generation uses `GET_BASHED_HOME/bin` shdoc in CI.
