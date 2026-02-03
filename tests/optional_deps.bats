#!/usr/bin/env bats

@test "optional deps are added when feature enabled" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  HOME="$HOME" bash ./install.sh --auto --prefix "$HOME/.get-bashed" --force --features git_signing --install git --dry-run > "$TMPDIR/out"

  run grep -F "would install: gnupg" "$TMPDIR/out"
  [ "$status" -eq 0 ]
}
