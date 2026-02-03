#!/usr/bin/env bash
# @file test-setup
# @brief Fetch Bats test helper libraries.
# @description
#     Downloads bats-support, bats-assert, and bats-file into tests/lib.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$ROOT_DIR/tests/lib"

mkdir -p "$LIB_DIR"

clone_lib() {
  local name="$1" repo="$2" sha="$3"
  local dest="$LIB_DIR/$name"
  if [[ -d "$dest/.git" ]]; then
    return 0
  fi
  git clone --quiet "$repo" "$dest"
  git -C "$dest" checkout --quiet "$sha"
}

clone_lib "bats-support" "https://github.com/bats-core/bats-support.git" "64e7436962affbe15974d181173c37e1fac70073"
clone_lib "bats-assert" "https://github.com/bats-core/bats-assert.git" "123860c029685bc0a4150ed57ee97fc7f7cc9d31"
clone_lib "bats-file" "https://github.com/bats-core/bats-file.git" "13ad5e2ffcc360281432db3d43a306f7b3667d60"

echo "Bats libs ready in $LIB_DIR"
