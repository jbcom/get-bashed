#!/usr/bin/env bash
# @file 50-tool-init
# @brief get-bashed module: 50-tool-init
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Cargo (idempotent)
_maybe_source "$HOME/.cargo/env"

# Prompt + env managers
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
