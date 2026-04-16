#!/usr/bin/env bash
# @file 70-bash-it
# @brief get-bashed module: 70-bash-it
# @description
#     Optional bash-it integration.

if [[ "${GET_BASHED_USE_BASH_IT:-0}" == "1" ]]; then
  GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  BASH_IT="$GET_BASHED_HOME/vendor/bash-it"
  if [[ -r "$BASH_IT/bash_it.sh" ]]; then
    if [[ -z "${GET_BASHED_BASH_IT_LOADED:-}" ]]; then
      # shellcheck disable=SC1090,SC1091
      source "$BASH_IT/bash_it.sh"
      export GET_BASHED_BASH_IT_LOADED=1
    fi

    get_bashed_component() {
      local action="${1:-enable}"
      shift || true
      case "$action" in
        enable|disable) ;;
        *) action="enable" ;;
      esac
      NO_COLOR=1 bash-it search "$@" "--${action}"
    }

    if [[ -n "${GET_BASHED_BASH_IT_SEARCH:-}" ]]; then
      if [[ -z "${GET_BASHED_BASH_IT_APPLIED:-}" ]]; then
        GET_BASHED_BASH_IT_APPLIED=1
        action="${GET_BASHED_BASH_IT_ACTION:-enable}"
        case "$action" in
          enable|disable) ;;
          *) action="enable" ;;
        esac
        refresh=""
        if [[ "${GET_BASHED_BASH_IT_REFRESH:-0}" == "1" ]]; then
          refresh="--refresh"
        fi
        IFS=',' read -r -a terms <<<"${GET_BASHED_BASH_IT_SEARCH}"
        NO_COLOR=1 bash-it search "${terms[@]}" "--${action}" $refresh
      fi
    fi
  fi
fi
