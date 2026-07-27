#!/usr/bin/env bash
# @file 50-tool-init
# @brief get-bashed module: 50-tool-init
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Cargo
if [[ -z "${GET_BASHED_CARGO_ENV_LOADED:-}" ]] && [[ -r "$HOME/.cargo/env" ]]; then
  _maybe_source "$HOME/.cargo/env"
  export GET_BASHED_CARGO_ENV_LOADED=1
fi

# Prompt + env managers
if command -v starship >/dev/null 2>&1 && [[ -z "${GET_BASHED_STARSHIP_INIT:-}" ]]; then
  eval "$(starship init bash)"
  export GET_BASHED_STARSHIP_INIT=1
fi

if command -v direnv >/dev/null 2>&1 && [[ -z "${GET_BASHED_DIRENV_HOOKED:-}" ]]; then
  eval "$(direnv hook bash)"
  export GET_BASHED_DIRENV_HOOKED=1
fi
