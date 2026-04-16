#!/usr/bin/env bash
# shellcheck disable=SC1090
# @file 99-secrets
# @brief get-bashed module: 99-secrets
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Source all secret snippets from ~/.get-bashed/secrets.d
GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
GET_BASHED_SECRETS_DIR="${GET_BASHED_SECRETS_DIR:-$GET_BASHED_HOME/secrets.d}"

get_bashed_secret_mode() {
  local file="$1"

  if stat -c '%a' "$file" >/dev/null 2>&1; then
    stat -c '%a' "$file"
    return 0
  fi
  if stat -f '%Lp' "$file" >/dev/null 2>&1; then
    stat -f '%Lp' "$file"
    return 0
  fi

  return 1
}

get_bashed_secret_is_private() {
  local file="$1"
  local mode_raw
  local mode

  mode_raw="$(get_bashed_secret_mode "$file" || true)"
  [[ "$mode_raw" =~ ^[0-7]{3,4}$ ]] || return 1
  mode=$((8#$mode_raw))
  (( (mode & 077) == 0 ))
}

if [[ -d "$GET_BASHED_SECRETS_DIR" ]]; then
  for f in "$GET_BASHED_SECRETS_DIR"/*.sh; do
    [[ -e "$f" ]] || continue
    [[ -f "$f" && -r "$f" ]] || continue
    if get_bashed_secret_is_private "$f"; then
      source "$f"
    else
      printf 'get-bashed: skipping %s; require owner-only permissions on secret files\n' "$f" >&2
    fi
  done
fi
