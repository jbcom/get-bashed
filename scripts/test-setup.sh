#!/usr/bin/env bash
# @file test-setup
# @brief Fetch Bats test helper libraries.
# @description
#     Downloads bats-support, bats-assert, and bats-file into tests/lib.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="$ROOT_DIR/tests/lib"
LOCK_DIR="${TEST_SETUP_LOCK_DIR:-$LIB_DIR/.setup.lock}"

# shellcheck disable=SC1091
source "$ROOT_DIR/installers/sources.sh"

mkdir -p "$LIB_DIR"

release_setup_lock() {
  [[ -d "$LOCK_DIR" ]] || return 0
  rm -rf "$LOCK_DIR"
}

acquire_setup_lock() {
  local owner_pid=""
  local attempts=0

  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [[ -r "$LOCK_DIR/pid" ]]; then
      owner_pid="$(<"$LOCK_DIR/pid")"
      if [[ -n "$owner_pid" ]] && ! kill -0 "$owner_pid" 2>/dev/null; then
        rm -rf "$LOCK_DIR"
        continue
      fi
    fi

    attempts=$(( attempts + 1 ))
    if (( attempts > 300 )); then
      echo "Timed out waiting for test helper setup lock: $LOCK_DIR" >&2
      return 1
    fi
    sleep 0.1
  done

  printf '%s\n' "$$" > "$LOCK_DIR/pid"
  trap release_setup_lock EXIT
}

clone_lib() {
  local name="$1" repo="$2" sha="$3"
  local dest="$LIB_DIR/$name"
  local current_remote current_sha

  if [[ -d "$dest/.git" ]]; then
    current_remote="$(git -C "$dest" remote get-url origin 2>/dev/null || true)"
    current_sha="$(git -C "$dest" rev-parse HEAD 2>/dev/null || true)"
    if [[ "$current_remote" == "$repo" && "$current_sha" == "$sha" ]]; then
      return 0
    fi
    rm -rf "$dest"
  fi
  if [[ -d "$dest" ]]; then
    rm -rf "$dest"
  fi
  git clone --quiet "$repo" "$dest"
  git -C "$dest" checkout --quiet "$sha"
}

main() {
  acquire_setup_lock
  clone_lib "bats-support" "${GET_BASHED_GIT_SOURCES["bats_support"]}" "${GET_BASHED_GIT_REFS["bats_support"]}"
  clone_lib "bats-assert" "${GET_BASHED_GIT_SOURCES["bats_assert"]}" "${GET_BASHED_GIT_REFS["bats_assert"]}"
  clone_lib "bats-file" "${GET_BASHED_GIT_SOURCES["bats_file"]}" "${GET_BASHED_GIT_REFS["bats_file"]}"

  echo "Bats libs ready in $LIB_DIR"
}

if [[ "${TEST_SETUP_SKIP_MAIN:-0}" != "1" ]]; then
  main "$@"
fi
