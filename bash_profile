# @file bash_profile
# @brief get-bashed login entrypoint.
# @description
#     Loads Homebrew shellenv (if present) then delegates to bashrc.

# Return early if not interactive
[[ $- != *i* ]] && return

# Homebrew shellenv (optional)
if command -v brew >/dev/null 2>&1; then
  if [[ "$(uname -m)" == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    eval "$(brew shellenv)"
  fi
fi

# Hand off to interactive rc
GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
if [[ -r "$GET_BASHED_HOME/bashrc" ]]; then
  source "$GET_BASHED_HOME/bashrc"
elif [[ -r "$HOME/.bashrc" ]]; then
  source "$HOME/.bashrc"
fi
