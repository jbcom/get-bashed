#!/usr/bin/env bats

@test "link-dotfiles creates symlinks and updates gitconfig" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  USER_NAME="Jane Doe"
  USER_EMAIL="jane@example.com"

  HOME="$HOME" bash ./install.sh --auto --link-dotfiles --name "$USER_NAME" --email "$USER_EMAIL" --prefix "$HOME/.get-bashed" --force

  [ -L "$HOME/.bashrc" ]
  [ -L "$HOME/.bash_profile" ]
  [ -L "$HOME/.inputrc" ]
  [ -L "$HOME/.bash_aliases" ]
  [ -L "$HOME/.vimrc" ]
  [ -L "$HOME/.gitconfig" ]

  run grep -F "name = ${USER_NAME}" "$HOME/.get-bashed/gitconfig"
  [ "$status" -eq 0 ]
  run grep -F "email = ${USER_EMAIL}" "$HOME/.get-bashed/gitconfig"
  [ "$status" -eq 0 ]
}

@test "link-dotfiles backs up existing dotfiles" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  echo "legacy" > "$HOME/.bashrc"

  HOME="$HOME" bash ./install.sh --auto --link-dotfiles --prefix "$HOME/.get-bashed" --force

  [ -L "$HOME/.bashrc" ]
  [ -d "$HOME/.get-bashed/backup" ]
  run ls "$HOME/.get-bashed/backup" | grep -E '^bashrc\.[0-9]+'
  [ "$status" -eq 0 ]
}
