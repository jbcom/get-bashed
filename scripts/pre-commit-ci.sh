#!/usr/bin/env bash
# @file pre-commit-ci
# @brief Pre-commit runner using get-bashed installers.
# @description
#     Bootstraps tools via get-bashed then runs pre-commit.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

. "$ROOT_DIR/scripts/ci-setup.sh" "pre_commit,actionlint,shellcheck,bashate,shdoc"

if command -v pre-commit >/dev/null 2>&1; then
  pre-commit run --all-files
else
  echo "pre-commit not found after install" >&2
  exit 1
fi
