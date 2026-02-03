#!/usr/bin/env bash
# @file 40-completions
# @brief get-bashed module: 40-completions
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Bash completion core (Homebrew)
if command -v brew >/dev/null 2>&1; then
  export BASH_COMPLETION_USER_DIR="$HOME/.local/share/bash-completion"
  if [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]]; then
    . "/opt/homebrew/etc/profile.d/bash_completion.sh"
  elif [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]]; then
    . "/usr/local/etc/profile.d/bash_completion.sh"
  fi
fi

# Sudo completion
complete -cf sudo

# asdf completions
if command -v asdf >/dev/null 2>&1; then
  . <(asdf completion bash)
fi
