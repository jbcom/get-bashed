#!/usr/bin/env bats

load test_helper

@test "installer writes to prefix and wires bashrc" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR" bash ./install.sh --prefix "$TMPDIR/.get-bashed" --force

  assert_file_exist "$TMPDIR/.get-bashed/bashrc"
  assert_dir_exist "$TMPDIR/.get-bashed/bashrc.d"

  run grep -F "# get-bashed: source modular bashrc" "$TMPDIR/.bashrc"
  assert_success

  run grep -F "# get-bashed: source login bash_profile" "$TMPDIR/.bash_profile"
  assert_success
}
