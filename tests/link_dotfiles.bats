#!/usr/bin/env bats

load test_helper

@test "link-dotfiles creates symlinks and updates gitconfig" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  USER_NAME="Jane Doe"
  USER_EMAIL="jane@example.com"

  HOME="$HOME" bash ./install.sh --auto --link-dotfiles --name "$USER_NAME" --email "$USER_EMAIL" --prefix "$HOME/.get-bashed" --force

  run test -L "$HOME/.bashrc"
  assert_success
  run test -L "$HOME/.bash_profile"
  assert_success
  run test -L "$HOME/.inputrc"
  assert_success
  run test -L "$HOME/.bash_aliases"
  assert_success
  run test -L "$HOME/.vimrc"
  assert_success
  run test -L "$HOME/.gitconfig"
  assert_success

  run grep -F "name = ${USER_NAME}" "$HOME/.get-bashed/gitconfig"
  assert_success
  run grep -F "email = ${USER_EMAIL}" "$HOME/.get-bashed/gitconfig"
  assert_success
}

@test "link-dotfiles backs up existing dotfiles" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  echo "legacy" > "$HOME/.bashrc"

  HOME="$HOME" bash ./install.sh --auto --link-dotfiles --prefix "$HOME/.get-bashed" --force

  run test -L "$HOME/.bashrc"
  assert_success
  assert_dir_exist "$HOME/.get-bashed/backup"
  run ls "$HOME/.get-bashed/backup" | grep -E '^bashrc\.[0-9]+'
  assert_success
}
