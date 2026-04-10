# @file bash_profile
# @brief get-bashed login entrypoint.
# @description
#     Loads Homebrew shellenv (if present) then delegates to bashrc.

# Return early if not interactive
[[ $- != *i* ]] && return

# Homebrew shellenv (optional)
if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(dirname "$(dirname "$(command -v brew)")")"
  export HOMEBREW_PREFIX="$BREW_PREFIX"
  export HOMEBREW_CELLAR="$BREW_PREFIX/Cellar"
  export HOMEBREW_REPOSITORY="$BREW_PREFIX"
  export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin${PATH+:$PATH}"
  export MANPATH="$BREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="$BREW_PREFIX/share/info:${INFOPATH:-}"
fi

# Hand off to interactive rc
GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
if [[ -r "$GET_BASHED_HOME/bashrc" ]]; then
  source "$GET_BASHED_HOME/bashrc"
elif [[ -r "$HOME/.bashrc" ]]; then
  source "$HOME/.bashrc"
fi
