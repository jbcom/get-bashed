#!/usr/bin/env bash
# @file ci-setup
# @brief CI setup using get-bashed installers.
# @description
#     Detects GitHub Actions runner environment and installs tools into
#     a writable prefix via get-bashed.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Prefer RUNNER_TEMP, then RUNNER_TOOL_CACHE, then /tmp
PREFIX="${GET_BASHED_HOME:-${RUNNER_TEMP:-${RUNNER_TOOL_CACHE:-/tmp}}/get-bashed}"
export GET_BASHED_HOME="$PREFIX"
export PATH="$GET_BASHED_HOME/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"
export HOMEBREW_NO_INSTALL_CLEANUP="${HOMEBREW_NO_INSTALL_CLEANUP:-1}"
export HOMEBREW_NO_ENV_HINTS="${HOMEBREW_NO_ENV_HINTS:-1}"

INSTALLS="${1:-shdoc,actionlint,shellcheck,bashate}"

"$ROOT_DIR/install.sh" --auto --install "$INSTALLS"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'GET_BASHED_HOME=%s\n' "$GET_BASHED_HOME" >> "$GITHUB_ENV"
fi

if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$GET_BASHED_HOME/bin" >> "$GITHUB_PATH"
fi

echo "CI tools installed to $GET_BASHED_HOME"
