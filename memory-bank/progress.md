# Progress

## What works
- Installer framework with profiles/features/installers
- Memory bank + docs pipeline
- CI workflows and release automation
- Pre-commit policy and security docs

## What's left
- Run `scripts/gen-docs.sh` after shdoc install (done)
- Create release branch and open PR for initial release
- Review CI for shdoc availability on all platforms

## Known issues
- shdoc not available via Homebrew on macOS; uses local prefix install.
- Ensure docs generation uses `GET_BASHED_HOME/bin` shdoc in CI.
