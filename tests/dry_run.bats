#!/usr/bin/env bats

load test_helper

@test "dry-run does not create files or modify shell startup" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  run env HOME="$HOME" ./install.sh --auto --profiles minimal --prefix "$HOME/.get-bashed" --dry-run
  assert_success
  assert_output --partial "Dry run enabled. No changes will be made."

  assert_dir_not_exist "$HOME/.get-bashed"
  assert_file_not_exist "$HOME/.bashrc"
  assert_file_not_exist "$HOME/.bash_profile"
}

@test "dry-run with --with-ui does not try to install dialog in non-interactive mode" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/brew.log"
  mkdir -p "$HOME" "$FAKEBIN"

  cat > "$FAKEBIN/brew" <<EOF
#!/bin/sh
printf '%s\n' "\$*" > "$LOG"
exit 99
EOF
  chmod +x "$FAKEBIN/brew"

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" ./install.sh --with-ui --prefix "$HOME/.get-bashed" --dry-run
  assert_success
  assert_output --partial "Dry run enabled. No changes will be made."

  if [[ -e "$LOG" ]]; then
    fail "dry-run should not try to install dialog before switching to non-interactive mode"
  fi
}
