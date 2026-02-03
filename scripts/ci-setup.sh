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

INSTALLS="${1:-shdoc,actionlint,shellcheck,bashate}"

"$ROOT_DIR/install.sh" --auto --install "$INSTALLS"

echo "CI tools installed to $GET_BASHED_HOME"
