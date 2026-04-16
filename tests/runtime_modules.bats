#!/usr/bin/env bats

load test_helper

@test "secrets module sources only local secrets and not Doppler output" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  PREFIX="$HOME/.get-bashed"
  FAKEBIN="$TMPDIR/bin"
  mkdir -p "$PREFIX/secrets.d" "$FAKEBIN"

  cat > "$PREFIX/secrets.d/10-local.sh" <<'EOF'
export LOCAL_SECRET=1
EOF

  cat > "$FAKEBIN/doppler" <<'EOF'
#!/bin/sh
echo 'export DOPPLER_SECRET=1'
exit 0
EOF
  chmod +x "$FAKEBIN/doppler"

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" GET_BASHED_USE_DOPPLER=1 PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -lc 'source bashrc.d/99-secrets.sh; printf "local=%s doppler=%s\n" "${LOCAL_SECRET:-0}" "${DOPPLER_SECRET:-0}"'
  assert_success
  assert_output "local=1 doppler=0"
}

@test "doppler module exposes explicit doppler_shell helper" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  MARKER="$TMPDIR/doppler-args"
  mkdir -p "$FAKEBIN"

  cat > "$FAKEBIN/doppler" <<EOF
#!/bin/sh
printf '%s\n' "\$*" > "$MARKER"
exit 0
EOF
  chmod +x "$FAKEBIN/doppler"

  run env HOME="$HOME" GET_BASHED_USE_DOPPLER=1 PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -lc 'source bashrc.d/66-doppler.sh; doppler_shell'
  assert_success
  run cat "$MARKER"
  assert_output "run -- bash"
}

@test "asdf module activates git installs without command pre-existence" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME/.asdf/bin" "$HOME/.asdf/shims"

  cat > "$HOME/.asdf/asdf.sh" <<'EOF'
export ASDF_ACTIVATED=1
EOF

  run env HOME="$HOME" PATH="/usr/bin:/bin" "$MODERN_BASH" -lc 'source bashrc.d/10-helpers.sh; source bashrc.d/20-path.sh; source bashrc.d/60-asdf.sh; printf "activated=%s path=%s\n" "${ASDF_ACTIVATED:-0}" "$PATH"'
  assert_success
  assert_output --partial "activated=1"
  assert_output --partial "$HOME/.asdf/bin"
  assert_output --partial "$HOME/.asdf/shims"
}

@test "auto_tools uses generated pinned npm package specs" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  PREFIX="$HOME/.get-bashed"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/asdf.log"
  mkdir -p "$HOME" "$PREFIX" "$FAKEBIN"

  cat > "$PREFIX/get-bashed-pins.sh" <<'EOF'
GET_BASHED_GEMINI_CLI_PACKAGE_SPEC="@google/gemini-cli@0.38.1"
GET_BASHED_SONAR_SCAN_PACKAGE_SPEC="@sonar/scan@4.3.6"
EOF

  cat > "$FAKEBIN/asdf" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$LOG"
case "\$*" in
  "exec npm list -g --depth=0 @google/gemini-cli@0.38.1"|"exec npm list -g --depth=0 @sonar/scan@4.3.6")
    exit 1
    ;;
esac
exit 0
EOF
  chmod +x "$FAKEBIN/asdf"

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" GET_BASHED_AUTO_TOOLS=1 PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source bashrc.d/65-tools.sh'
  assert_success

  run cat "$LOG"
  assert_output --partial "exec npm --version"
  assert_output --partial "exec npm list -g --depth=0 @google/gemini-cli@0.38.1"
  assert_output --partial "exec npm list -g --depth=0 @sonar/scan@4.3.6"
  assert_output --partial "exec npm install -g @google/gemini-cli@0.38.1"
  assert_output --partial "exec npm install -g @sonar/scan@4.3.6"
}

@test "auto_tools skips reinstall when pinned npm packages already exist" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  PREFIX="$HOME/.get-bashed"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/asdf.log"
  mkdir -p "$HOME" "$PREFIX" "$FAKEBIN"

  cat > "$PREFIX/get-bashed-pins.sh" <<'EOF'
GET_BASHED_GEMINI_CLI_PACKAGE_SPEC="@google/gemini-cli@0.38.1"
GET_BASHED_SONAR_SCAN_PACKAGE_SPEC="@sonar/scan@4.3.6"
EOF

  cat > "$FAKEBIN/asdf" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$LOG"
exit 0
EOF
  chmod +x "$FAKEBIN/asdf"

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" GET_BASHED_AUTO_TOOLS=1 PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source bashrc.d/65-tools.sh'
  assert_success

  run cat "$LOG"
  assert_output --partial "exec npm list -g --depth=0 @google/gemini-cli@0.38.1"
  assert_output --partial "exec npm list -g --depth=0 @sonar/scan@4.3.6"
  refute_output --partial "exec npm install -g @google/gemini-cli@0.38.1"
  refute_output --partial "exec npm install -g @sonar/scan@4.3.6"
}

@test "buildflags module avoids empty path segments and prefixes existing values cleanly" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/homebrew/bin"
  BREW_ROOT="$TMPDIR/homebrew"
  mkdir -p "$HOME" "$FAKEBIN"
  mkdir -p \
    "$BREW_ROOT/opt/openssl@3/lib/pkgconfig" \
    "$BREW_ROOT/opt/openssl@3/include" \
    "$BREW_ROOT/opt/readline/lib/pkgconfig" \
    "$BREW_ROOT/opt/readline/include"

  cat > "$FAKEBIN/brew" <<EOF
#!/bin/sh
if [ "\$1" = "--prefix" ]; then
  printf '%s\n' "$BREW_ROOT"
  exit 0
fi
exit 1
EOF
  chmod +x "$FAKEBIN/brew"

  run env HOME="$HOME" GET_BASHED_BUILD_FLAGS=1 PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'PKG_CONFIG_PATH=/seed/pkg LIBRARY_PATH=/seed/lib CPATH=/seed/include LDFLAGS="-existing-ld" CPPFLAGS="-existing-cpp" PYTHON_CONFIGURE_OPTS="--seed-opt"; source bashrc.d/10-helpers.sh; source bashrc.d/30-buildflags.sh; printf "pkg=%s\nlib=%s\ncpath=%s\nld=%s\ncpp=%s\npy=%s\n" "$PKG_CONFIG_PATH" "$LIBRARY_PATH" "$CPATH" "$LDFLAGS" "$CPPFLAGS" "$PYTHON_CONFIGURE_OPTS"'
  assert_success
  assert_output --partial "pkg=$BREW_ROOT/opt/openssl@3/lib/pkgconfig:$BREW_ROOT/opt/readline/lib/pkgconfig:/seed/pkg"
  assert_output --partial "lib=$BREW_ROOT/opt/openssl@3/lib:$BREW_ROOT/opt/readline/lib:/seed/lib"
  assert_output --partial "cpath=$BREW_ROOT/opt/openssl@3/include:$BREW_ROOT/opt/readline/include:/seed/include"
  assert_output --partial "ld=-L$BREW_ROOT/opt/openssl@3/lib -L$BREW_ROOT/opt/readline/lib -existing-ld"
  assert_output --partial "cpp=-I$BREW_ROOT/opt/openssl@3/include -I$BREW_ROOT/opt/readline/include -existing-cpp"
  assert_output --partial "py=--with-openssl=$BREW_ROOT/opt/openssl@3 --with-readline=editline --seed-opt"
  refute_output --partial "::"
  refute_output --partial ":/seed/pkg:"
}

@test "tool-init module sources cargo env and shell hooks when tools exist" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  mkdir -p "$HOME/.cargo" "$FAKEBIN"

  cat > "$HOME/.cargo/env" <<'EOF'
export CARGO_ENV_LOADED=1
EOF

  cat > "$FAKEBIN/starship" <<'EOF'
#!/bin/sh
if [ "$1" = "init" ] && [ "$2" = "bash" ]; then
  printf 'export STARSHIP_INIT=1\n'
fi
EOF
  chmod +x "$FAKEBIN/starship"

  cat > "$FAKEBIN/direnv" <<'EOF'
#!/bin/sh
if [ "$1" = "hook" ] && [ "$2" = "bash" ]; then
  printf 'export DIRENV_HOOKED=1\n'
fi
EOF
  chmod +x "$FAKEBIN/direnv"

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source bashrc.d/10-helpers.sh; source bashrc.d/50-tool-init.sh; printf "cargo=%s starship=%s direnv=%s\n" "${CARGO_ENV_LOADED:-0}" "${STARSHIP_INIT:-0}" "${DIRENV_HOOKED:-0}"'
  assert_success
  assert_output "cargo=1 starship=1 direnv=1"
}

@test "tool-init module is idempotent when sourced multiple times" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  mkdir -p "$HOME/.cargo" "$HOME/.cargo/bin" "$FAKEBIN"

  cat > "$HOME/.cargo/env" <<'EOF'
export CARGO_ENV_COUNT=$(( ${CARGO_ENV_COUNT:-0} + 1 ))
export PATH="$HOME/.cargo/bin${PATH+:$PATH}"
EOF

  cat > "$FAKEBIN/starship" <<'EOF'
#!/bin/sh
if [ "$1" = "init" ] && [ "$2" = "bash" ]; then
  printf 'export STARSHIP_INIT_COUNT=$(( ${STARSHIP_INIT_COUNT:-0} + 1 ))\n'
  printf 'export PROMPT_COMMAND="starship${PROMPT_COMMAND:+;%s}"\n' "${PROMPT_COMMAND:-}"
fi
EOF
  chmod +x "$FAKEBIN/starship"

  cat > "$FAKEBIN/direnv" <<'EOF'
#!/bin/sh
if [ "$1" = "hook" ] && [ "$2" = "bash" ]; then
  printf 'export DIRENV_HOOK_COUNT=$(( ${DIRENV_HOOK_COUNT:-0} + 1 ))\n'
  printf 'export PROMPT_COMMAND="direnv${PROMPT_COMMAND:+;%s}"\n' "${PROMPT_COMMAND:-}"
fi
EOF
  chmod +x "$FAKEBIN/direnv"

  run env HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c 'source bashrc.d/10-helpers.sh; source bashrc.d/50-tool-init.sh; source bashrc.d/50-tool-init.sh; printf "cargo=%s starship=%s direnv=%s prompt=%s path=%s\n" "${CARGO_ENV_COUNT:-0}" "${STARSHIP_INIT_COUNT:-0}" "${DIRENV_HOOK_COUNT:-0}" "${PROMPT_COMMAND:-}" "$PATH"'
  assert_success
  assert_output --partial "cargo=1 starship=1 direnv=1"
  assert_output --partial "prompt=direnv;starship"
  refute_output --partial "$HOME/.cargo/bin:$HOME/.cargo/bin"
}

@test "bash-it module sources installed framework and applies queued search once" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  PREFIX="$HOME/.get-bashed"
  LOG="$TMPDIR/bash-it.log"
  mkdir -p "$PREFIX/vendor/bash-it"

  cat > "$PREFIX/vendor/bash-it/bash_it.sh" <<'EOF'
#!/usr/bin/env bash
export BASH_IT_LOADED=1
bash-it() {
  printf '%s\n' "$*" >> "$BASH_IT_LOG"
}
EOF

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" GET_BASHED_USE_BASH_IT=1 GET_BASHED_BASH_IT_SEARCH="git,docker" GET_BASHED_BASH_IT_ACTION=enable GET_BASHED_BASH_IT_REFRESH=1 BASH_IT_LOG="$LOG" "$MODERN_BASH" -c 'source bashrc.d/70-bash-it.sh; get_bashed_component disable aliases; printf "loaded=%s applied=%s\n" "${BASH_IT_LOADED:-0}" "${GET_BASHED_BASH_IT_APPLIED:-0}"'
  assert_success
  assert_output "loaded=1 applied=1"

  run cat "$LOG"
  assert_output --partial "search git docker --enable --refresh"
  assert_output --partial "search aliases --disable"
}

@test "bash-it module is idempotent when sourced multiple times" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  PREFIX="$HOME/.get-bashed"
  LOG="$TMPDIR/bash-it.log"
  mkdir -p "$PREFIX/vendor/bash-it"

  cat > "$PREFIX/vendor/bash-it/bash_it.sh" <<'EOF'
#!/usr/bin/env bash
export BASH_IT_LOAD_COUNT=$(( ${BASH_IT_LOAD_COUNT:-0} + 1 ))
bash-it() {
  printf '%s\n' "$*" >> "$BASH_IT_LOG"
}
EOF

  run env HOME="$HOME" GET_BASHED_HOME="$PREFIX" GET_BASHED_USE_BASH_IT=1 GET_BASHED_BASH_IT_SEARCH="git" BASH_IT_LOG="$LOG" "$MODERN_BASH" -c 'source bashrc.d/70-bash-it.sh; source bashrc.d/70-bash-it.sh; printf "loaded=%s applied=%s\n" "${BASH_IT_LOAD_COUNT:-0}" "${GET_BASHED_BASH_IT_APPLIED:-0}"'
  assert_success
  assert_output "loaded=1 applied=1"

  run awk 'END { print NR }' "$LOG"
  assert_success
  assert_output "1"
}

@test "ssh-agent module creates ~/.ssh and starts agent on first run" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/ssh-agent.log"
  mkdir -p "$HOME" "$FAKEBIN"

  cat > "$FAKEBIN/ssh-agent" <<EOF
#!/bin/sh
printf '%s\n' "\$*" > "$LOG"
sock=""
while [ "\$#" -gt 0 ]; do
  if [ "\$1" = "-a" ]; then
    shift
    sock="\$1"
  fi
  shift
done
printf 'SSH_AUTH_SOCK=%s; export SSH_AUTH_SOCK; SSH_AGENT_PID=123; export SSH_AGENT_PID; echo Agent pid 123;\n' "\$sock"
EOF
  chmod +x "$FAKEBIN/ssh-agent"

  cat > "$FAKEBIN/ssh-add" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$FAKEBIN/ssh-add"

  run env -u SSH_AUTH_SOCK -u SSH_AGENT_PID HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" GET_BASHED_SSH_AGENT=1 GET_BASHED_TEST_TTY=1 "$MODERN_BASH" -c 'source bashrc.d/95-ssh-agent.sh; printf "sock=%s pid=%s\n" "${SSH_AUTH_SOCK:-}" "${SSH_AGENT_PID:-}"'
  assert_success
  assert_output --partial "sock=$HOME/.ssh/agent.sock"
  assert_output --partial "pid=123"
  assert_dir_exist "$HOME/.ssh"

  run cat "$LOG"
  assert_output "-a $HOME/.ssh/agent.sock -s"
}

@test "ssh-agent module reuses an existing socket without starting a new agent" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  SOCK="$HOME/.ssh/agent.sock"
  LOG="$TMPDIR/ssh-agent.log"
  REAL_SSH_AGENT="$(command -v ssh-agent)"
  mkdir -p "$HOME/.ssh" "$FAKEBIN"

  [[ -n "$REAL_SSH_AGENT" ]] || fail "expected ssh-agent to be available for fixture setup"
  eval "$("$REAL_SSH_AGENT" -a "$SOCK" -s)" >/dev/null
  FIXTURE_SSH_AGENT_PID="$SSH_AGENT_PID"
  [[ -S "$SOCK" ]] || fail "expected reusable socket fixture at $SOCK"

  cat > "$FAKEBIN/ssh-add" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$FAKEBIN/ssh-add"

  cat > "$FAKEBIN/ssh-agent" <<EOF
#!/bin/sh
printf '%s\n' "\$*" > "$LOG"
exit 99
EOF
  chmod +x "$FAKEBIN/ssh-agent"

  run env -u SSH_AUTH_SOCK -u SSH_AGENT_PID HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" GET_BASHED_SSH_AGENT=1 GET_BASHED_TEST_TTY=1 "$MODERN_BASH" -c 'source bashrc.d/95-ssh-agent.sh; printf "sock=%s\n" "${SSH_AUTH_SOCK:-}"'

  kill "$FIXTURE_SSH_AGENT_PID" 2>/dev/null || true

  assert_success
  assert_output --partial "sock=$SOCK"

  if [[ -e "$LOG" ]]; then
    fail "ssh-agent should not have been invoked when an existing socket was reusable"
  fi
}

@test "ssh-agent module only auto-adds default keys once per agent" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  FAKEBIN="$TMPDIR/bin"
  SOCK="$HOME/.ssh/agent.sock"
  LOG="$TMPDIR/ssh-add.log"
  REAL_SSH_AGENT="$(command -v ssh-agent)"
  mkdir -p "$HOME/.ssh" "$FAKEBIN"

  [[ -n "$REAL_SSH_AGENT" ]] || fail "expected ssh-agent to be available for fixture setup"
  printf 'rsa\n' > "$HOME/.ssh/id_rsa"
  printf 'ed25519\n' > "$HOME/.ssh/id_ed25519"
  eval "$("$REAL_SSH_AGENT" -a "$SOCK" -s)" >/dev/null
  FIXTURE_SSH_AGENT_PID="$SSH_AGENT_PID"
  [[ -S "$SOCK" ]] || fail "expected reusable socket fixture at $SOCK"

  cat > "$FAKEBIN/ssh-add" <<EOF
#!/bin/sh
if [ "\$1" = "-l" ]; then
  exit 1
fi
printf '%s\n' "\$*" >> "$LOG"
exit 0
EOF
  chmod +x "$FAKEBIN/ssh-add"

  run env -u SSH_AUTH_SOCK -u SSH_AGENT_PID HOME="$HOME" PATH="$FAKEBIN:/usr/bin:/bin" GET_BASHED_SSH_AGENT=1 GET_BASHED_TEST_TTY=1 "$MODERN_BASH" -c 'source bashrc.d/95-ssh-agent.sh; source bashrc.d/95-ssh-agent.sh; printf "sock=%s added_for=%s\n" "${SSH_AUTH_SOCK:-}" "${GET_BASHED_SSH_KEYS_ADDED_FOR:-}"'

  kill "$FIXTURE_SSH_AGENT_PID" 2>/dev/null || true

  assert_success
  assert_output --partial "sock=$SOCK"
  assert_output --partial "added_for=$SOCK:"

  run awk 'END { print NR }' "$LOG"
  assert_success
  assert_output "2"
}
