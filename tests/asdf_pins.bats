#!/usr/bin/env bats

load test_helper

@test "install_asdf_runtime uses pinned plugin source and version" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  ASDF_DATA_DIR="$TMPDIR/asdf"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/calls.log"
  mkdir -p "$HOME" "$ASDF_DATA_DIR" "$FAKEBIN"

  cat > "$FAKEBIN/asdf" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$LOG"
case "\$1 \$2" in
  "plugin list")
    exit 0
    ;;
  "plugin add")
    mkdir -p "$ASDF_DATA_DIR/plugins/nodejs/.git"
    exit 0
    ;;
  "install nodejs")
    exit 0
    ;;
  "set --home")
    exit 0
    ;;
esac
exit 0
EOF
  chmod +x "$FAKEBIN/asdf"

  cat > "$FAKEBIN/git" <<EOF
#!/bin/sh
printf 'git %s\n' "\$*" >> "$LOG"
exit 0
EOF
  chmod +x "$FAKEBIN/git"

  run env HOME="$HOME" ASDF_DATA_DIR="$ASDF_DATA_DIR" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source installers/_helpers.sh; install_asdf_runtime nodejs'
  assert_success

  run cat "$LOG"
  assert_output --partial "plugin list"
  assert_output --partial "plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git"
  assert_output --partial "git -C $ASDF_DATA_DIR/plugins/nodejs checkout 779c8dc84b3bdab38c2c80622d315c2c3267f74b"
  assert_output --partial "install nodejs 24.14.1"
  assert_output --partial "set --home nodejs 24.14.1"
}

@test "install_asdf_runtime fails when no pin exists" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  mkdir -p "$HOME" "$FAKEBIN"

  cat > "$FAKEBIN/asdf" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$FAKEBIN/asdf"

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source installers/_helpers.sh; install_asdf_runtime unknown_runtime'
  assert_failure
  assert_output --partial "No pinned asdf version configured for unknown_runtime."
}

@test "pipx_install uses pinned package spec when configured" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/pipx.log"
  PREFIX="$TMPDIR/prefix"
  mkdir -p "$HOME" "$FAKEBIN"

  cat > "$FAKEBIN/pipx" <<EOF
#!/bin/sh
printf 'HOME=%s BIN=%s MAN=%s CMD=%s\n' \
  "\${PIPX_HOME:-}" "\${PIPX_BIN_DIR:-}" "\${PIPX_MAN_DIR:-}" "\$*" >> "$LOG"
exit 0
EOF
  chmod +x "$FAKEBIN/pipx"

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source installers/_helpers.sh; pipx_install pre_commit'
  assert_success

  run cat "$LOG"
  assert_output --partial "HOME=$PREFIX/pipx"
  assert_output --partial "BIN=$PREFIX/bin"
  assert_output --partial "MAN=$PREFIX/share/man"
  assert_output --partial "CMD=install pre-commit==4.5.1"
}

@test "pip fallback uses pinned package spec when configured" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/pip.log"
  PREFIX="$TMPDIR/prefix"
  mkdir -p "$HOME" "$FAKEBIN"

  cat > "$FAKEBIN/python3" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$LOG"
if [ "\$1" = "-m" ] && [ "\$2" = "pip" ] && [ "\$3" = "--version" ]; then
  exit 0
fi
exit 0
EOF
  chmod +x "$FAKEBIN/python3"

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source installers/_helpers.sh; source installers/tools.sh; _using_brew(){ return 1; }; install_tool pipx'
  assert_success

  run cat "$LOG"
  assert_output --partial "-m pip install --prefix $PREFIX pipx==1.11.1"
}
