#!/usr/bin/env bats

load test_helper

@test "installer writes to prefix and wires bashrc" {
  TMPDIR="$(mktemp -d)"
  TEST_HOME="$TMPDIR"
  HOME="$TEST_HOME" bash ./install.sh --auto --prefix "$TEST_HOME/.get-bashed" --force

  assert_file_exist "$TEST_HOME/.get-bashed/bashrc"
  assert_dir_exist "$TEST_HOME/.get-bashed/bashrc.d"

  run grep -F "# get-bashed: source modular bashrc" "$TEST_HOME/.bashrc"
  assert_success

  run grep -F "# get-bashed: source login bash_profile" "$TEST_HOME/.bash_profile"
  assert_success
}
