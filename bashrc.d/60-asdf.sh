#!/usr/bin/env bash
# shellcheck disable=SC1091
# @file 60-asdf
# @brief get-bashed module: 60-asdf
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# asdf: full activation for interactive shells
if [[ -r "$HOME/.asdf/asdf.sh" ]]; then
  . "$HOME/.asdf/asdf.sh"
elif BREW_PREFIX="$(get_brew_prefix)" && [[ -r "$BREW_PREFIX/opt/asdf/libexec/asdf.sh" ]]; then
  . "$BREW_PREFIX/opt/asdf/libexec/asdf.sh"
elif command -v asdf >/dev/null 2>&1; then
  :
fi
