#!/usr/bin/env bats

load test_helper

@test "installer writes get-bashedrc with git identity" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  TEST_HOME="$HOME"

  USER_NAME="Jane Doe"
  USER_EMAIL="jane@example.com"

  HOME="$TEST_HOME" bash ./install.sh --auto --name "$USER_NAME" --email "$USER_EMAIL" --prefix "$TEST_HOME/.get-bashed" --force

  run grep -F "GET_BASHED_USER_NAME=\"${USER_NAME}\"" "$TEST_HOME/.get-bashed/get-bashedrc.sh"
  assert_success
  run grep -F "GET_BASHED_USER_EMAIL=\"${USER_EMAIL}\"" "$TEST_HOME/.get-bashed/get-bashedrc.sh"
  assert_success
}

@test "cli features override profile defaults" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  TEST_HOME="$HOME"

  HOME="$TEST_HOME" bash ./install.sh --auto --profiles minimal --features gnu_over_bsd --prefix "$TEST_HOME/.get-bashed" --force

  run grep -F "export GET_BASHED_GNU=1" "$TEST_HOME/.get-bashed/get-bashedrc.sh"
  assert_success
}
