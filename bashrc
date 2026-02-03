# @file bashrc
# @brief get-bashed interactive entrypoint.
# @description
#     Loads modular runtime files in order.

# Return early if not interactive
[[ $- != *i* ]] && return

GET_BASHED_HOME="${GET_BASHED_HOME:-$HOME/.get-bashed}"
GET_BASHED_RC_DIR="${GET_BASHED_RC_DIR:-$GET_BASHED_HOME/bashrc.d}"

if [[ -r "$GET_BASHED_HOME/get-bashedrc.sh" ]]; then
  source "$GET_BASHED_HOME/get-bashedrc.sh"
fi

for f in "$GET_BASHED_RC_DIR"/[0-9][0-9]-*.sh; do
  [[ -r "$f" ]] && source "$f"
done
