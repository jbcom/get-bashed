#!/usr/bin/env bash
# shellcheck disable=SC1090
# @file 99-secrets
# @brief get-bashed module: 99-secrets
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Source all secret snippets from ~/.get-bashed/secrets.d
GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
GET_BASHED_SECRETS_DIR="${GET_BASHED_SECRETS_DIR:-$GET_BASHED_HOME/secrets.d}"

if [[ -d "$GET_BASHED_SECRETS_DIR" ]]; then
  for f in "$GET_BASHED_SECRETS_DIR"/*.sh; do
    [[ -r "$f" ]] && source "$f"
  done
fi
