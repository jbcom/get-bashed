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
  fi
fi
