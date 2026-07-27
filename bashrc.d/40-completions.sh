#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# @file 40-completions
# @brief get-bashed module: 40-completions
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Bash completion core (Homebrew/Linuxbrew)
if [[ -z "${GET_BASHED_BREW_COMPLETIONS_LOADED:-}" ]] && BREW_PREFIX="$(get_brew_prefix)"; then
  export BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"
  if [[ -r "$BREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
    . "$BREW_PREFIX/etc/profile.d/bash_completion.sh"
    export GET_BASHED_BREW_COMPLETIONS_LOADED=1
  fi
fi

# Sudo completion
complete -cf sudo

# asdf completions
if [[ -z "${GET_BASHED_ASDF_COMPLETIONS_LOADED:-}" ]] && command -v asdf >/dev/null 2>&1; then
  . <(asdf completion bash)
  export GET_BASHED_ASDF_COMPLETIONS_LOADED=1
fi
