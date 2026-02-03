#!/usr/bin/env bats

@test "installer writes get-bashedrc with git identity" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  USER_NAME="Jane Doe"
  USER_EMAIL="jane@example.com"

  HOME="$HOME" bash ./install.sh --auto --name "$USER_NAME" --email "$USER_EMAIL" --prefix "$HOME/.get-bashed" --force

  run grep -F "GET_BASHED_USER_NAME=\"${USER_NAME}\"" "$HOME/.get-bashed/get-bashedrc.sh"
  [ "$status" -eq 0 ]
  run grep -F "GET_BASHED_USER_EMAIL=\"${USER_EMAIL}\"" "$HOME/.get-bashed/get-bashedrc.sh"
  [ "$status" -eq 0 ]
}
