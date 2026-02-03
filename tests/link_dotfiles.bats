#!/usr/bin/env bats

load test_helper

@test "link-dotfiles creates symlinks and updates gitconfig" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  TEST_HOME="$HOME"

  USER_NAME="Jane Doe"
  USER_EMAIL="jane@example.com"

  HOME="$TEST_HOME" bash ./install.sh --auto --link-dotfiles --name "$USER_NAME" --email "$USER_EMAIL" --prefix "$TEST_HOME/.get-bashed" --force

  run test -L "$TEST_HOME/.bashrc"
  assert_success
  run test -L "$TEST_HOME/.bash_profile"
  assert_success
  run test -L "$TEST_HOME/.inputrc"
  assert_success
  run test -L "$TEST_HOME/.bash_aliases"
  assert_success
  run test -L "$TEST_HOME/.vimrc"
  assert_success
  run test -L "$TEST_HOME/.gitconfig"
  assert_success

  run grep -F "name = ${USER_NAME}" "$TEST_HOME/.get-bashed/gitconfig"
  assert_success
  run grep -F "email = ${USER_EMAIL}" "$TEST_HOME/.get-bashed/gitconfig"
  assert_success
}

@test "link-dotfiles backs up existing dotfiles" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  TEST_HOME="$HOME"
  echo "legacy" > "$HOME/.bashrc"

  HOME="$TEST_HOME" bash ./install.sh --auto --link-dotfiles --prefix "$TEST_HOME/.get-bashed" --force

  run test -L "$TEST_HOME/.bashrc"
  assert_success
  assert_dir_exist "$TEST_HOME/.get-bashed/backup"
  run bash -c 'ls "$1" | grep -E "^bashrc\\.[0-9]+"' _ "$TEST_HOME/.get-bashed/backup"
  assert_success
}
