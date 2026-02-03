# @file 70-bash-it
# @brief get-bashed module: 70-bash-it
# @description
#     Optional bash-it integration.

if [[ "${GET_BASHED_USE_BASH_IT:-0}" == "1" ]]; then
  GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  BASH_IT="$GET_BASHED_HOME/vendor/bash-it"
  if [[ -r "$BASH_IT/bash_it.sh" ]]; then
    # shellcheck disable=SC1090
    source "$BASH_IT/bash_it.sh"

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
        local action="${GET_BASHED_BASH_IT_ACTION:-enable}"
        case "$action" in
          enable|disable) ;;
          *) action="enable" ;;
        esac
        local refresh=""
        if [[ "${GET_BASHED_BASH_IT_REFRESH:-0}" == "1" ]]; then
          refresh="--refresh"
        fi
        IFS=',' read -r -a terms <<<"${GET_BASHED_BASH_IT_SEARCH}"
        NO_COLOR=1 bash-it search "${terms[@]}" "--${action}" $refresh
      fi
    fi
  fi
fi
