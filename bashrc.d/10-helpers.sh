# @file 10-helpers
# @brief get-bashed module: 10-helpers
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# PATH helpers + safe source
_path_add_front() { [[ -d "$1" ]] && PATH="$1:${PATH}"; }
_path_add_back()  { [[ -d "$1" ]] && PATH="${PATH}:$1"; }
_path_dedupe() {
  awk -v RS=: '!seen[$0]++ { out = out (NR==1?"":":") $0 } END{ print out }' <<<"$PATH"
}

declare -f path_add >/dev/null 2>&1 || path_add() {
  _path_add_front "$@"
  PATH="$(_path_dedupe)"
}

_maybe_source() { [[ -r "$1" ]] && source "$1"; }
