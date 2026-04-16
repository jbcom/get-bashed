#!/usr/bin/env bash

TESTS_DIR="${BATS_TEST_DIRNAME}"
REPO_ROOT="$(cd "${TESTS_DIR}/.." && pwd)"

if [[ ! -r "${TESTS_DIR}/lib/bats-support/load.bash" ]] ||
  [[ ! -r "${TESTS_DIR}/lib/bats-assert/load.bash" ]] ||
  [[ ! -r "${TESTS_DIR}/lib/bats-file/load.bash" ]]; then
  bash "${REPO_ROOT}/scripts/test-setup.sh" >/dev/null
fi

load "${BATS_TEST_DIRNAME}/lib/bats-support/load"
load "${BATS_TEST_DIRNAME}/lib/bats-assert/load"
load "${BATS_TEST_DIRNAME}/lib/bats-file/load"

detect_modern_bash() {
  local candidate version
  local -a candidates=()

  [[ -n "${GET_BASHED_TEST_BASH:-}" ]] && candidates+=("$GET_BASHED_TEST_BASH")
  if command -v bash >/dev/null 2>&1; then
    candidates+=("$(command -v bash)")
  fi
  candidates+=("/opt/homebrew/bin/bash" "/usr/local/bin/bash" "/bin/bash")

  for candidate in "${candidates[@]}"; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    # shellcheck disable=SC2016
    version="$("$candidate" -c 'printf "%s" "${BASH_VERSINFO[0]}"' 2>/dev/null || true)"
    [[ "$version" =~ ^[0-9]+$ ]] || continue
    if (( version >= 4 )); then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

MODERN_BASH="${MODERN_BASH:-$(detect_modern_bash)}"
export MODERN_BASH
