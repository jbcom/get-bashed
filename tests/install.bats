#!/usr/bin/env bats

@test "installer writes to prefix and wires bashrc" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR" bash ./install.sh --prefix "$TMPDIR/.get-bashed" --force

  [ -f "$TMPDIR/.get-bashed/bashrc" ]
  [ -d "$TMPDIR/.get-bashed/bashrc.d" ]

  run grep -F "# get-bashed: source modular bashrc" "$TMPDIR/.bashrc"
  [ "$status" -eq 0 ]

  run grep -F "# get-bashed: source login bash_profile" "$TMPDIR/.bash_profile"
  [ "$status" -eq 0 ]
}
