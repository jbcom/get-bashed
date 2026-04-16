#!/usr/bin/env bash
# shellcheck disable=SC1090
# @file 10-helpers
# @brief get-bashed module: 10-helpers
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# PATH helpers + safe source
_path_add_front() { [[ -d "$1" ]] && PATH="$1:${PATH}"; }
_path_add_back()  { [[ -d "$1" ]] && PATH="${PATH}:$1"; }
_path_dedupe() {
  awk -v RS=: '!seen[$0]++ { out = out (NR==1?"":":") $0 } END{ print out }' <<<"$PATH"
}

declare -f get_brew_bin >/dev/null 2>&1 || get_brew_bin() {
  local candidate
  local -a candidates=()

  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  if [[ -n "${GET_BASHED_BREW_BIN_CANDIDATES:-}" ]]; then
    # shellcheck disable=SC2206
    candidates=(${GET_BASHED_BREW_BIN_CANDIDATES})
  else
    candidates=(
      "/opt/homebrew/bin/brew"
      "/usr/local/bin/brew"
      "/home/linuxbrew/.linuxbrew/bin/brew"
    )
  fi

  for candidate in "${candidates[@]}"; do
    [[ -x "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done

  return 1
}

declare -f get_brew_prefix >/dev/null 2>&1 || get_brew_prefix() {
  local brew_bin prefix

  brew_bin="$(get_brew_bin)" || return 1
  prefix="$("$brew_bin" --prefix 2>/dev/null || true)"
  [[ -n "$prefix" && -d "$prefix" ]] || return 1
  printf '%s\n' "$prefix"
}

declare -f path_add >/dev/null 2>&1 || path_add() {
  _path_add_front "$@"
}

_maybe_source() { [[ -r "$1" ]] && source "$1"; }
