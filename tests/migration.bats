#!/usr/bin/env bats

load test_helper

@test "legacy bashrc.d collisions are migrated without overwriting managed modules" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME/.bashrc.d"
  PREFIX="$HOME/.get-bashed"

  echo "# custom legacy module" > "$HOME/.bashrc.d/20-path.sh"

  run env HOME="$HOME" ./install.sh --auto --prefix "$PREFIX"
  assert_success

  assert_file_exist "$PREFIX/bashrc.d/20-path.sh"
  run grep -F "@file 20-path" "$PREFIX/bashrc.d/20-path.sh"
  assert_success
  assert_file_exist "$PREFIX/bashrc.d/migrated-1-20-path.sh"
}
