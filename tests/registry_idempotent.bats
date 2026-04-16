#!/usr/bin/env bats

load test_helper

@test "tool registry exposes expected installers" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  TEST_HOME="$HOME"

  HOME="$TEST_HOME" ./install.sh --auto --list-installers > "$TMPDIR/list"

  run grep -F " - git" "$TMPDIR/list"
  assert_success
  run grep -F " - bash_it" "$TMPDIR/list"
  assert_success
}
