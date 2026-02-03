# @file 60-asdf
# @brief get-bashed module: 60-asdf
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# asdf: full activation for interactive shells
if command -v asdf >/dev/null 2>&1; then
  if [[ -r "$HOME/.asdf/asdf.sh" ]]; then
    . "$HOME/.asdf/asdf.sh"
  elif [[ -r "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]]; then
    . "/opt/homebrew/opt/asdf/libexec/asdf.sh"
  elif [[ -r "/usr/local/opt/asdf/libexec/asdf.sh" ]]; then
    . "/usr/local/opt/asdf/libexec/asdf.sh"
  fi
fi
