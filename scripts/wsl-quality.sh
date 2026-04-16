#!/usr/bin/env bash
# @file wsl-quality
# @brief Run CI quality checks inside WSL.
# @description
#     Normalizes the nested GitHub Actions environment and reuses the same
#     quality targets as local and hosted Linux/macOS runs.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export RUNNER_TEMP=/tmp
export RUNNER_TOOL_CACHE=/tmp
unset GITHUB_ENV GITHUB_PATH

make lint
make test
