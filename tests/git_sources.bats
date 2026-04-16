#!/usr/bin/env bats

load test_helper

setup_git_repo() {
  local repo="$1"

  git init -q "$repo"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" config user.email "test@example.com"
}

@test "git-backed tool installs realign existing clone to pinned ref and target dir" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  PREFIX="$HOME/.get-bashed"
  REPO="$TMPDIR/bash-it-repo"
  mkdir -p "$HOME" "$PREFIX/vendor"

  setup_git_repo "$REPO"
  printf '#!/bin/sh\nexit 0\n' > "$REPO/bash_it.sh"
  git -C "$REPO" add bash_it.sh
  git -C "$REPO" commit -m first >/dev/null
  SHA1="$(git -C "$REPO" rev-parse HEAD)"
  git -C "$REPO" tag v3.2.0 "$SHA1"

  printf '#!/bin/sh\necho second\n' > "$REPO/bash_it.sh"
  git -C "$REPO" commit -am second >/dev/null
  SHA2="$(git -C "$REPO" rev-parse HEAD)"

  git config --global url."$REPO".insteadOf "https://github.com/Bash-it/bash-it.git"
  git clone "$REPO" "$PREFIX/vendor/bash-it" >/dev/null 2>&1
  git -C "$PREFIX/vendor/bash-it" checkout "$SHA2" >/dev/null 2>&1

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" "$MODERN_BASH" -c 'source installers/_helpers.sh; source installers/tools.sh; install_tool bash_it'
  assert_success

  run git -C "$PREFIX/vendor/bash-it" rev-parse HEAD
  assert_output "$SHA1"
  assert_dir_exist "$PREFIX/vendor/bash-it"
  assert_file_not_exist "$PREFIX/vendor/bash_it/bash_it.sh"
}

@test "git-based asdf install realigns an existing clone to the pinned ref" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  REPO="$TMPDIR/asdf-repo"
  mkdir -p "$HOME"

  setup_git_repo "$REPO"
  printf 'first\n' > "$REPO/README.md"
  git -C "$REPO" add README.md
  git -C "$REPO" commit -m first >/dev/null
  SHA1="$(git -C "$REPO" rev-parse HEAD)"
  git -C "$REPO" tag v0.18.1 "$SHA1"

  printf 'second\n' > "$REPO/README.md"
  git -C "$REPO" commit -am second >/dev/null
  SHA2="$(git -C "$REPO" rev-parse HEAD)"

  git config --global url."$REPO".insteadOf "https://github.com/asdf-vm/asdf.git"
  git clone "$REPO" "$HOME/.asdf" >/dev/null 2>&1
  git -C "$HOME/.asdf" checkout "$SHA2" >/dev/null 2>&1

  run env HOME="$HOME" "$MODERN_BASH" -c 'source installers/_helpers.sh; _using_asdf(){ return 1; }; _using_brew(){ return 1; }; install_asdf'
  assert_success

  run git -C "$HOME/.asdf" rev-parse HEAD
  assert_output "$SHA1"
}
