#!/usr/bin/env bash
# @file verify-install
# @brief Minimal verification of get-bashed install wiring.
# @description
#     Installs into a temp HOME and verifies symlinks and structure.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
TEST_HOME="$TMPDIR/home"
mkdir -p "$TEST_HOME"

HOME="$TEST_HOME" "$ROOT_DIR/install.sh" --auto --profiles minimal --link-dotfiles --name "Test User" --email "test@example.com"

[[ -L "$TEST_HOME/.bashrc" ]]
[[ -L "$TEST_HOME/.bash_profile" ]]
[[ -L "$TEST_HOME/.inputrc" ]]
[[ -L "$TEST_HOME/.bash_aliases" ]]
[[ -L "$TEST_HOME/.vimrc" ]]
[[ -L "$TEST_HOME/.gitconfig" ]]

[[ -d "$TEST_HOME/.get-bashed/bashrc.d" ]]
[[ -d "$TEST_HOME/.get-bashed/secrets.d" ]]

if [[ -d "$TEST_HOME/.bashrc.d" ]]; then
  echo "Unexpected .bashrc.d created under HOME" >&2
  exit 1
fi

if [[ -d "$TEST_HOME/.secrets.d" ]]; then
  echo "Unexpected .secrets.d created under HOME" >&2
  exit 1
fi

echo "verify-install: ok"
