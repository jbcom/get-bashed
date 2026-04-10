# @file bash_aliases
# @brief get-bashed aliases.
# @description
#     Default aliases sourced by bashrc when present.

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -la --icons'
  alias la='eza -a --icons'
  alias l='eza -F --icons'
else
  alias ll='ls -alF'
  alias la='ls -A'
  alias l='ls -CF'
fi
