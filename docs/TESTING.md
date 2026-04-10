---
title: TESTING.md — get-bashed
updated: 2026-04-10
status: current
---

# Testing

## Strategy

Tests validate installer behavior and shell wiring, not runtime shell customizations. The goal is to confirm that:

- The installer copies the correct files and writes the correct config.
- Feature flags and profiles produce the expected `get-bashedrc.sh` output.
- Dotfile linking and backup behavior is correct.
- Install verification passes on a clean prefix.

## Test Framework

Tests use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) with three helper libraries:

- `bats-support` — core BATS helpers
- `bats-assert` — assertion library (`assert_success`, `assert_output`, etc.)
- `bats-file` — file and directory assertions (`assert_file_exist`, `assert_dir_exist`)

Helper libraries are pinned to specific commit SHAs in `scripts/test-setup.sh`. Do not update these without auditing the new commits.

## Running Tests

Fetch helper libraries (one time):

```bash
./scripts/test-setup.sh
```

Run the full suite:

```bash
bats tests
```

Or via Make:

```bash
make test
```

Make runs `./scripts/test-setup.sh` before `bats tests`.

## Test Files

| File | Coverage |
|---|---|
| `tests/install.bats` | Installer copies files and wires `~/.bashrc` / `~/.bash_profile` |
| `tests/config_output.bats` | Feature flags and profiles produce correct `get-bashedrc.sh` |
| `tests/link_dotfiles.bats` | `--link-dotfiles` creates symlinks and backs up existing files |
| `tests/registry_idempotent.bats` | Installer can be re-run without error |
| `tests/optional_deps.bats` | Optional dependency gating by feature flags |

## Isolation

Every test creates its own temp `HOME` directory:

```bash
TMPDIR="$(mktemp -d)"
HOME="$TMPDIR"
```

This prevents any test from modifying the developer's real home directory. Tests clean up via temp directory expiry; they do not explicitly clean up on failure.

## CI Coverage

The `tests` job in `ci.yml` runs:

1. `scripts/ci-setup.sh "bats"` — installs bats into `GET_BASHED_HOME`.
2. `scripts/test-setup.sh` — fetches pinned bats helper libraries.
3. `bats tests` — runs the full suite.
4. `scripts/verify-install.sh` — validates that a basic install produces the expected wiring.

## Install Verification

`scripts/verify-install.sh` performs a smoke-test install and checks:

- `~/.get-bashed/bashrc` exists.
- `~/.get-bashed/bashrc.d/` exists.
- `~/.get-bashed/get-bashedrc.sh` was written.
- `~/.bashrc` contains the expected source snippet.

This runs after BATS to catch regressions that unit tests may miss.

## Linting

The `lint` job runs pre-commit:

```bash
pre-commit run --all-files
```

Pre-commit hooks run:

- `shellcheck` — shell script linting.
- `bashate` — PEP 8 style for shell (max line length 120).
- `actionlint` — GitHub Actions workflow linting.
- `gitleaks` — secret detection.
- Standard file hygiene (trailing whitespace, end-of-file newlines, YAML/JSON validation).

Run locally:

```bash
make lint
# or
pre-commit run --all-files
```

Install the pre-commit hook:

```bash
pre-commit install
```

## Adding Tests

1. Add a new `.bats` file in `tests/` or add `@test` blocks to an existing file.
2. Load helpers at the top: `load test_helper`.
3. Create a temp HOME per test to isolate side effects.
4. Use `run` for commands whose exit code you want to inspect.
5. Use `assert_success`, `assert_failure`, `assert_output`, `assert_file_exist`, etc.

Example:

```bash
@test "my new test" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR"

  HOME="$HOME" bash ./install.sh --auto --prefix "$HOME/.get-bashed" --force

  assert_file_exist "$HOME/.get-bashed/get-bashedrc.sh"
}
```

## Known Gaps

- No coverage of runtime module behavior (module sourcing, conditional flags).
- shdoc availability is not tested in CI (shdoc unavailable via Homebrew on macOS; installed locally in CI via `GET_BASHED_HOME/bin`).
