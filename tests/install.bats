#!/usr/bin/env bats

load test_helper

@test "installer writes to prefix and wires bashrc" {
  TMPDIR="$(mktemp -d)"
  TEST_HOME="$TMPDIR"
  HOME="$TEST_HOME" ./install.sh --auto --prefix "$TEST_HOME/.get-bashed" --force

  assert_file_exist "$TEST_HOME/.get-bashed/bashrc"
  assert_dir_exist "$TEST_HOME/.get-bashed/bashrc.d"

  run grep -F "# get-bashed: source modular bashrc" "$TEST_HOME/.bashrc"
  assert_success

  run grep -F "# get-bashed: source login bash_profile" "$TEST_HOME/.bash_profile"
  assert_success
}

@test "installer splits comma-delimited install lists" {
  TMPDIR="$(mktemp -d)"
  TEST_HOME="$TMPDIR/home"
  mkdir -p "$TEST_HOME"

  HOME="$TEST_HOME" ./install.sh --auto --prefix "$TEST_HOME/.get-bashed" --dry-run --install "pre_commit,actionlint,shellcheck" > "$TMPDIR/out"

  run grep -F "would install: pre_commit" "$TMPDIR/out"
  assert_success
  run grep -F "would install: actionlint" "$TMPDIR/out"
  assert_success
  run grep -F "would install: shellcheck" "$TMPDIR/out"
  assert_success
}

@test "actionlint fallback verifies pinned checksum before install" {
  TMPDIR="$(mktemp -d)"
  TEST_HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/log"
  mkdir -p "$TEST_HOME" "$FAKEBIN"

  cat > "$FAKEBIN/curl" <<EOF
#!/bin/sh
printf 'curl %s\n' "\$*" >> "$LOG"
outfile=
while [ "\$#" -gt 0 ]; do
  if [ "\$1" = "-o" ]; then
    shift
    outfile="\$1"
    break
  fi
  shift
done
printf 'archive' > "\$outfile"
EOF
  chmod +x "$FAKEBIN/curl"

  cat > "$FAKEBIN/sha256sum" <<'EOF'
#!/bin/sh
printf '%s  %s\n' 'aba9ced2dee8d27fecca3dc7feb1a7f9a52caefa1eb46f3271ea66b6e0e6953f' "$1"
EOF
  chmod +x "$FAKEBIN/sha256sum"

  cat > "$FAKEBIN/tar" <<'EOF'
#!/bin/sh
dest="."
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-C" ]; then
    shift
    dest="$1"
  fi
  shift
done
printf '#!/bin/sh\nexit 0\n' > "$dest/actionlint"
EOF
  chmod +x "$FAKEBIN/tar"

  run env HOME="$TEST_HOME" GET_BASHED_HOME="$TEST_HOME/.get-bashed" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source installers/_helpers.sh; _using_brew(){ return 1; }; apt_install(){ return 1; }; install_actionlint'
  assert_success
  assert_file_exist "$TEST_HOME/.get-bashed/bin/actionlint"
}

@test "actionlint fallback aborts on checksum mismatch" {
  TMPDIR="$(mktemp -d)"
  TEST_HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  mkdir -p "$TEST_HOME" "$FAKEBIN"

  cat > "$FAKEBIN/curl" <<'EOF'
#!/bin/sh
outfile=
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    shift
    outfile="$1"
    break
  fi
  shift
done
printf 'archive' > "$outfile"
EOF
  chmod +x "$FAKEBIN/curl"

  cat > "$FAKEBIN/sha256sum" <<'EOF'
#!/bin/sh
printf '%s  %s\n' 'deadbeef' "$1"
EOF
  chmod +x "$FAKEBIN/sha256sum"

  cat > "$FAKEBIN/tar" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$FAKEBIN/tar"

  run env HOME="$TEST_HOME" GET_BASHED_HOME="$TEST_HOME/.get-bashed" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source installers/_helpers.sh; _using_brew(){ return 1; }; apt_install(){ return 1; }; install_actionlint'
  assert_failure
  assert_output --partial "Actionlint checksum mismatch"
}
