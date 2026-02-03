#!/usr/bin/env bats

@test "tool registry exposes expected installers" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  HOME="$HOME" bash ./install.sh --auto --list-installers > "$TMPDIR/list"

  run grep -F " - git" "$TMPDIR/list"
  [ "$status" -eq 0 ]
  run grep -F " - bash_it" "$TMPDIR/list"
  [ "$status" -eq 0 ]
}
