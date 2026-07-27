#!/usr/bin/env bats
# shellcheck disable=SC2016

load test_helper

setup_fake_brew() {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  BREW_PREFIX="$TMPDIR/linuxbrew"

  mkdir -p "$HOME" "$FAKEBIN" "$BREW_PREFIX"

  cat > "$FAKEBIN/brew" <<EOF
#!/bin/sh
if [ "\$1" = "shellenv" ]; then
  printf '%s\n' "export HOMEBREW_PREFIX=$BREW_PREFIX"
  printf '%s\n' "export HOMEBREW_CELLAR=$BREW_PREFIX/Cellar"
  printf '%s\n' "export HOMEBREW_REPOSITORY=$BREW_PREFIX"
  printf '%s\n' "export PATH=$BREW_PREFIX/bin:$BREW_PREFIX/sbin:\$PATH"
  exit 0
fi
if [ "\$1" = "--prefix" ]; then
  printf '%s\n' "$BREW_PREFIX"
  exit 0
fi
exit 1
EOF
  chmod +x "$FAKEBIN/brew"
}

@test "path module uses brew --prefix for GNU tool paths" {
  setup_fake_brew
  mkdir -p \
    "$BREW_PREFIX/opt/coreutils/libexec/gnubin" \
    "$BREW_PREFIX/opt/findutils/libexec/gnubin" \
    "$BREW_PREFIX/opt/gnu-sed/libexec/gnubin" \
    "$BREW_PREFIX/opt/gnu-tar/libexec/gnubin"

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" GET_BASHED_GNU=1 "$MODERN_BASH" -c 'source bashrc.d/10-helpers.sh; source bashrc.d/20-path.sh; printf "%s\n" "$PATH"'
  assert_success
  assert_output --partial "$BREW_PREFIX/opt/coreutils/libexec/gnubin"
  assert_output --partial "$BREW_PREFIX/opt/findutils/libexec/gnubin"
  refute_output --partial "$TMPDIR/opt/coreutils/libexec/gnubin"
}

@test "completions module sources bash completion from brew prefix" {
  setup_fake_brew
  mkdir -p "$BREW_PREFIX/etc/profile.d"

  cat > "$BREW_PREFIX/etc/profile.d/bash_completion.sh" <<'EOF'
export BREW_COMPLETION_LOADED=1
EOF

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source bashrc.d/10-helpers.sh; source bashrc.d/40-completions.sh; printf "loaded=%s user_dir=%s\n" "${BREW_COMPLETION_LOADED:-0}" "${BASH_COMPLETION_USER_DIR:-}"'
  assert_success
  assert_output "loaded=1 user_dir=$HOME/.local/share/bash-completion"
}

@test "completions module is idempotent across repeated sourcing" {
  setup_fake_brew
  mkdir -p "$BREW_PREFIX/etc/profile.d"

  cat > "$BREW_PREFIX/etc/profile.d/bash_completion.sh" <<'EOF'
export BREW_COMPLETION_COUNT=$(( ${BREW_COMPLETION_COUNT:-0} + 1 ))
EOF

  cat > "$FAKEBIN/asdf" <<'EOF'
#!/bin/sh
if [ "$1" = "completion" ] && [ "$2" = "bash" ]; then
  printf 'export ASDF_COMPLETION_COUNT=$(( ${ASDF_COMPLETION_COUNT:-0} + 1 ))\n'
fi
EOF
  chmod +x "$FAKEBIN/asdf"

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source bashrc.d/10-helpers.sh; source bashrc.d/40-completions.sh; source bashrc.d/40-completions.sh; printf "brew=%s asdf=%s user_dir=%s\n" "${BREW_COMPLETION_COUNT:-0}" "${ASDF_COMPLETION_COUNT:-0}" "${BASH_COMPLETION_USER_DIR:-}"'
  assert_success
  assert_output "brew=1 asdf=1 user_dir=$HOME/.local/share/bash-completion"
}

@test "asdf module sources Homebrew asdf from brew prefix" {
  setup_fake_brew
  mkdir -p "$BREW_PREFIX/opt/asdf/libexec"

  cat > "$BREW_PREFIX/opt/asdf/libexec/asdf.sh" <<'EOF'
export ASDF_BREW_LOADED=1
EOF

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source bashrc.d/10-helpers.sh; source bashrc.d/60-asdf.sh; printf "loaded=%s\n" "${ASDF_BREW_LOADED:-0}"'
  assert_success
  assert_output "loaded=1"
}

@test "bash_profile evaluates brew shellenv for login startup" {
  setup_fake_brew
  PROFILE_PATH="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/bash_profile"
  mkdir -p "$HOME/.get-bashed"

  cat > "$HOME/.get-bashed/bashrc" <<'EOF'
:
EOF

  run env -u HOMEBREW_PREFIX -u HOMEBREW_CELLAR -u HOMEBREW_REPOSITORY HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" GET_BASHED_HOME="$HOME/.get-bashed" "$MODERN_BASH" --noprofile --norc -ic "exec 2>/dev/null; source \"$PROFILE_PATH\"; printf 'prefix=%s\npath=%s\n' \"\${HOMEBREW_PREFIX:-}\" \"\$PATH\""
  assert_success
  assert_output --partial "prefix=$BREW_PREFIX"
  assert_output --partial "path=$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$FAKEBIN:/usr/bin:/bin"
}

@test "runtime helper resolves brew from fallback candidates outside PATH" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  BREW_PREFIX="$TMPDIR/linuxbrew"
  BREW_BIN="$BREW_PREFIX/bin/brew"
  mkdir -p "$HOME" "$BREW_PREFIX/bin"

  cat > "$BREW_BIN" <<EOF
#!/bin/sh
if [ "\$1" = "--prefix" ]; then
  printf '%s\n' "$BREW_PREFIX"
  exit 0
fi
exit 1
EOF
  chmod +x "$BREW_BIN"

  run env HOME="$HOME" PATH="/usr/bin:/bin" GET_BASHED_BREW_BIN_CANDIDATES="$BREW_BIN" "$MODERN_BASH" -c 'source bashrc.d/10-helpers.sh; printf "%s\n" "$(get_brew_prefix)"'
  assert_success
  assert_output "$BREW_PREFIX"
}

@test "bash_profile finds brew shellenv from fallback candidates outside PATH" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  BREW_PREFIX="$TMPDIR/linuxbrew"
  BREW_BIN="$BREW_PREFIX/bin/brew"
  PROFILE_PATH="$(cd "$BATS_TEST_DIRNAME/.." && pwd)/bash_profile"
  mkdir -p "$HOME/.get-bashed" "$BREW_PREFIX/bin" "$BREW_PREFIX/sbin"

  cat > "$HOME/.get-bashed/bashrc" <<'EOF'
:
EOF

  cat > "$BREW_BIN" <<EOF
#!/bin/sh
if [ "\$1" = "shellenv" ]; then
  printf '%s\n' "export HOMEBREW_PREFIX=$BREW_PREFIX"
  printf '%s\n' "export HOMEBREW_CELLAR=$BREW_PREFIX/Cellar"
  printf '%s\n' "export HOMEBREW_REPOSITORY=$BREW_PREFIX"
  printf '%s\n' "export PATH=$BREW_PREFIX/bin:$BREW_PREFIX/sbin:\$PATH"
  exit 0
fi
exit 1
EOF
  chmod +x "$BREW_BIN"

  run env -u HOMEBREW_PREFIX -u HOMEBREW_CELLAR -u HOMEBREW_REPOSITORY HOME="$HOME" PATH="/usr/bin:/bin" GET_BASHED_HOME="$HOME/.get-bashed" GET_BASHED_BREW_BIN_CANDIDATES="$BREW_BIN" "$MODERN_BASH" --noprofile --norc -ic "exec 2>/dev/null; source \"$PROFILE_PATH\"; printf 'prefix=%s\npath=%s\n' \"\${HOMEBREW_PREFIX:-}\" \"\$PATH\""
  assert_success
  assert_output --partial "prefix=$BREW_PREFIX"
  assert_output --partial "path=$BREW_PREFIX/bin:$BREW_PREFIX/sbin:/usr/bin:/bin"
}

@test "installer helper resolves brew from fallback candidates outside PATH" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  BREW_PREFIX="$TMPDIR/linuxbrew"
  BREW_BIN="$BREW_PREFIX/bin/brew"
  mkdir -p "$HOME" "$BREW_PREFIX/bin"

  cat > "$BREW_BIN" <<EOF
#!/bin/sh
printf '%s\n' "$BREW_BIN"
EOF
  chmod +x "$BREW_BIN"

  run env HOME="$HOME" PATH="/usr/bin:/bin" GET_BASHED_BREW_BIN_CANDIDATES="$BREW_BIN" "$MODERN_BASH" -c 'source installers/_helpers.sh; printf "%s\n" "$(_brew_bin)"'
  assert_success
  assert_output "$BREW_BIN"
}
