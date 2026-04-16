#!/usr/bin/env bats

load test_helper

@test "installer refreshes managed files and preserves unmanaged files under force" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  PREFIX="$HOME/.get-bashed"
  mkdir -p "$PREFIX/bashrc.d"

  echo "legacy" > "$PREFIX/bashrc"
  echo "custom" > "$PREFIX/bashrc.d/77-user.sh"
  echo "stale" > "$PREFIX/old-managed-file"
  printf 'bashrc\nold-managed-file\n' > "$PREFIX/.get-bashed-manifest"

  run env HOME="$HOME" ./install.sh --auto --force --prefix "$PREFIX"
  assert_success

  assert_file_exist "$PREFIX/bashrc"
  assert_file_exist "$PREFIX/bashrc.d/77-user.sh"
  assert_file_not_exist "$PREFIX/old-managed-file"

  run grep -F "@file bashrc" "$PREFIX/bashrc"
  assert_success
  run cat "$PREFIX/bashrc.d/77-user.sh"
  assert_output "custom"
}
