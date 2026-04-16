#!/usr/bin/env bats

load test_helper

@test "prompt selection applies bash_it through the shared feature resolver" {
  run "$MODERN_BASH" -c '
    set -euo pipefail
    REPO_DIR="$PWD"
    source installers/_helpers.sh
    source installers/tools.sh
    source installlib/config.sh
    source installlib/resolve.sh
    source installlib/ui.sh

    init_install_state
    load_installers
    input_file="$(mktemp)"
    cat > "$input_file" <<'"'"'INPUT'"'"'
y
n
n
n
n
n
y
n
INPUT
    run_prompt_selection < "$input_file"
    rm -f "$input_file"
    printf "bash_it=%s installs=%s\n" "$GET_BASHED_USE_BASH_IT" "${GROUP_INSTALLS:-}"
  '
  assert_success
  assert_output "bash_it=1 installs=bash_it"
}

@test "prompt selection can disable feature defaults inherited from a profile" {
  run "$MODERN_BASH" -c '
    set -euo pipefail
    REPO_DIR="$PWD"
    source installers/_helpers.sh
    source installers/tools.sh
    source installlib/config.sh
    source installlib/resolve.sh
    source installlib/ui.sh

    init_install_state
    PROFILES=dev
    resolve_requested_state

    input_file="$(mktemp)"
    cat > "$input_file" <<'"'"'INPUT'"'"'
y
n
n
n
n
n
n
n
INPUT
    run_prompt_selection < "$input_file"
    rm -f "$input_file"
    printf "gnu=%s build=%s auto=%s ssh=%s doppler=%s bash_it=%s signing=%s installs=%s\n" \
      "$GET_BASHED_GNU" "$GET_BASHED_BUILD_FLAGS" "$GET_BASHED_AUTO_TOOLS" "$GET_BASHED_SSH_AGENT" \
      "$GET_BASHED_USE_DOPPLER" "$GET_BASHED_USE_BASH_IT" "$GET_BASHED_GIT_SIGNING" "$INSTALLS"
  '
  assert_success
  assert_output "gnu=0 build=0 auto=0 ssh=0 doppler=0 bash_it=0 signing=0 installs=brew,asdf,gnu_tools,rg,fd,bat,fzf,jq,yq,tree,direnv,starship,nodejs,python,pipx,bashate,shellcheck,actionlint,bats,shdoc,bash"
}

@test "prompt selection preserves current feature defaults on empty answers" {
  run "$MODERN_BASH" -c '
    set -euo pipefail
    REPO_DIR="$PWD"
    source installers/_helpers.sh
    source installers/tools.sh
    source installlib/config.sh
    source installlib/resolve.sh
    source installlib/ui.sh

    init_install_state
    PROFILES=dev
    resolve_requested_state

    input_file="$(mktemp)"
    cat > "$input_file" <<'"'"'INPUT'"'"'
y







INPUT
    run_prompt_selection < "$input_file"
    rm -f "$input_file"
    printf "gnu=%s build=%s auto=%s ssh=%s doppler=%s bash_it=%s signing=%s installs=%s\n" \
      "$GET_BASHED_GNU" "$GET_BASHED_BUILD_FLAGS" "$GET_BASHED_AUTO_TOOLS" "$GET_BASHED_SSH_AGENT" \
      "$GET_BASHED_USE_DOPPLER" "$GET_BASHED_USE_BASH_IT" "$GET_BASHED_GIT_SIGNING" "$INSTALLS"
  '
  assert_success
  assert_output "gnu=1 build=1 auto=1 ssh=0 doppler=0 bash_it=0 signing=0 installs=brew,asdf,gnu_tools,rg,fd,bat,fzf,jq,yq,tree,direnv,starship,nodejs,python,pipx,bashate,shellcheck,actionlint,bats,shdoc,bash"
}

@test "prompt selection with --yes preserves resolved defaults instead of enabling every feature" {
  run "$MODERN_BASH" -c '
    set -euo pipefail
    REPO_DIR="$PWD"
    source installers/_helpers.sh
    source installers/tools.sh
    source installlib/config.sh
    source installlib/resolve.sh
    source installlib/ui.sh

    init_install_state
    YES=1
    PROFILES=dev
    resolve_requested_state
    run_prompt_selection
    printf "gnu=%s build=%s auto=%s ssh=%s doppler=%s bash_it=%s signing=%s installs=%s\n" \
      "$GET_BASHED_GNU" "$GET_BASHED_BUILD_FLAGS" "$GET_BASHED_AUTO_TOOLS" "$GET_BASHED_SSH_AGENT" \
      "$GET_BASHED_USE_DOPPLER" "$GET_BASHED_USE_BASH_IT" "$GET_BASHED_GIT_SIGNING" "$INSTALLS"
  '
  assert_success
  assert_output "gnu=1 build=1 auto=1 ssh=0 doppler=0 bash_it=0 signing=0 installs=brew,asdf,gnu_tools,rg,fd,bat,fzf,jq,yq,tree,direnv,starship,nodejs,python,pipx,bashate,shellcheck,actionlint,bats,shdoc,bash"
}

@test "dialog profile selection carries the profile installer bundle into the installer checklist defaults" {
  TMPDIR="$(mktemp -d)"
  FAKEBIN="$TMPDIR/bin"
  DIALOG_COUNT="$TMPDIR/dialog-count"
  mkdir -p "$FAKEBIN"

  cat > "$FAKEBIN/dialog" <<EOF
#!/bin/sh
count=0
if [ -r "$DIALOG_COUNT" ]; then
  count=\$(cat "$DIALOG_COUNT")
fi
count=\$((count + 1))
printf '%s\n' "\$count" > "$DIALOG_COUNT"
if [ "\$count" -eq 1 ]; then
  printf 'dev\n' >&2
  exit 0
fi
shift 8
first=1
while [ "\$#" -ge 3 ]; do
  tag="\$1"
  shift 2
  state="\$1"
  shift
  if [ "\$state" = "on" ]; then
    if [ "\$first" -eq 0 ]; then
      printf ' ' >&2
    fi
    printf '\"%s\"' "\$tag" >&2
    first=0
  fi
done
EOF
  chmod +x "$FAKEBIN/dialog"

  run env PATH="$FAKEBIN:/usr/bin:/bin" "$MODERN_BASH" -c '
    set -euo pipefail
    REPO_DIR="$PWD"
    source installers/_helpers.sh
    source installers/tools.sh
    source installlib/config.sh
    source installlib/resolve.sh
    source installlib/ui.sh

    init_install_state
    USER_NAME="Jane Doe"
    USER_EMAIL="jane@example.com"
    load_installers
    run_dialog_selection
    printf "gnu=%s build=%s auto=%s installs=%s\n" \
      "$GET_BASHED_GNU" "$GET_BASHED_BUILD_FLAGS" "$GET_BASHED_AUTO_TOOLS" "$INSTALLS"
  '
  assert_success
  assert_output --partial "gnu=1 build=1 auto=1"
  assert_output --partial "installs="
  [[ "$output" == *"brew"* ]]
  [[ "$output" == *"asdf"* ]]
  [[ "$output" == *"gnu_tools"* ]]
  [[ "$output" == *"rg"* ]]
  [[ "$output" == *"direnv"* ]]
  [[ "$output" == *"python"* ]]
  [[ "$output" == *"bashate"* ]]
  [[ "$output" != *"terraform"* ]]
}
