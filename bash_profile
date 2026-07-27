#!/usr/bin/env bash
# shellcheck disable=SC1091
# @file bash_profile
# @brief get-bashed login entrypoint.
# @description
#     Loads Homebrew shellenv (if present) then delegates to bashrc.

# shellcheck disable=SC1091
# Return early if not interactive
[[ $- != *i* ]] && return

_get_brew_bin() {
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

# Homebrew shellenv (optional)
if BREW_BIN="$(_get_brew_bin)"; then
  eval "$("$BREW_BIN" shellenv 2>/dev/null)"
fi

# Hand off to interactive rc
GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
if [[ -r "$GET_BASHED_HOME/bashrc" ]]; then
  source "$GET_BASHED_HOME/bashrc"
elif [[ -r "$HOME/.bashrc" ]]; then
  source "$HOME/.bashrc"
fi
