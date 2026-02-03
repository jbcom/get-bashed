#!/usr/bin/env bash
# @file 99-secrets
# @brief get-bashed module: 99-secrets
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Source all secret snippets from ~/.get-bashed/secrets.d
GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
GET_BASHED_SECRETS_DIR="${GET_BASHED_SECRETS_DIR:-$GET_BASHED_HOME/secrets.d}"

if [[ "${GET_BASHED_USE_DOPPLER:-0}" == "1" ]] && command -v doppler >/dev/null 2>&1; then
  set -a
  source <(doppler secrets download --no-file --format env)
  set +a
fi

if [[ -d "$GET_BASHED_SECRETS_DIR" ]]; then
  for f in "$GET_BASHED_SECRETS_DIR"/*.sh; do
    [[ -r "$f" ]] && source "$f"
  done
fi
