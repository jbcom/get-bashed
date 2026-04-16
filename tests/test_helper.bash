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

repo_search() {
  local pattern="$1"
  shift

  local path file exclude skip
  local -a files=()
  local -a filtered=()
  local -a excludes=()

  while (($#)); do
    case "$1" in
      --exclude)
        excludes+=("$2")
        shift 2
        ;;
      *)
        path="$1"
        if [[ -d "$path" ]]; then
          while IFS= read -r file; do
            files+=("$file")
          done < <(find "$path" -type f | sort)
        elif [[ -e "$path" ]]; then
          files+=("$path")
        fi
        shift
        ;;
    esac
  done

  [[ "${#files[@]}" -gt 0 ]] || return 1

  for file in "${files[@]}"; do
    skip=0
    for exclude in "${excludes[@]}"; do
      case "$file" in
        "$exclude"|*/"$exclude")
          skip=1
          break
          ;;
      esac
    done
    [[ "$skip" -eq 0 ]] && filtered+=("$file")
  done

  [[ "${#filtered[@]}" -gt 0 ]] || return 1
  grep -nE -- "$pattern" "${filtered[@]}"
}
