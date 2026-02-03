#!/usr/bin/env bash
# @file 20-path
# @brief get-bashed module: 20-path
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Base PATH (keep minimal and predictable)
GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
path_add "$GET_BASHED_HOME/bin"
path_add "$HOME/bin"
path_add "$HOME/.local/bin"
path_add "$HOME/.cargo/bin"

# Optional: Go
export GOBIN="${GOBIN:-$HOME/go/bin}"
path_add "$GOBIN"

# Optional: ASDF shims
path_add "$HOME/.asdf/shims"

# Optional: prefer GNU tools on macOS (requires Homebrew coreutils, gnu-sed, etc.)
# Set GET_BASHED_GNU=1 to enable.
if [[ "${GET_BASHED_GNU:-0}" == "1" ]] && command -v brew >/dev/null 2>&1; then
  path_add "$(brew --prefix coreutils)/libexec/gnubin"
  path_add "$(brew --prefix findutils)/libexec/gnubin"
  path_add "$(brew --prefix gnu-sed)/libexec/gnubin"
  path_add "$(brew --prefix gnu-tar)/libexec/gnubin"
fi

# Deduplicate once at end
PATH="$(_path_dedupe)"
export PATH
