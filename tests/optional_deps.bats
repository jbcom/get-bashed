#!/usr/bin/env bats

load test_helper

@test "optional deps are added when feature enabled" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  TEST_HOME="$HOME"

  HOME="$TEST_HOME" bash ./install.sh --auto --prefix "$TEST_HOME/.get-bashed" --force --features git_signing --install git --dry-run > "$TMPDIR/out"

  run grep -F "would install: gnupg" "$TMPDIR/out"
  assert_success
}
