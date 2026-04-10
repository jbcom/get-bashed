#!/usr/bin/env bash
# @file 90-functions
# @brief get-bashed module: 90-functions
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Quick extractor
ex () {
  local f="$1"
  [[ -f "$f" ]] || { echo "'$f' is not a valid file"; return 1; }
  local safe_f="$f"
  [[ "$safe_f" == -* ]] && safe_f="./$safe_f"
  case "$safe_f" in
    *.tar.bz2) tar xjf "$safe_f" ;;
    *.tar.gz)  tar xzf "$safe_f" ;;
    *.bz2)     bunzip2 "$safe_f" ;;
    *.rar)     unrar x "$safe_f" ;;
    *.gz)      gunzip "$safe_f" ;;
    *.tar)     tar xf "$safe_f" ;;
    *.tbz2)    tar xjf "$safe_f" ;;
    *.tgz)     tar xzf "$safe_f" ;;
    *.zip)     unzip "$safe_f" ;;
    *.Z)       uncompress "$safe_f" ;;
    *.7z)      7z x "$safe_f" ;;
    *)         echo "'$f' cannot be extracted via ex()" >&2; return 1 ;;
  esac
}

# @description Make a directory and immediately cd into it.
# @arg $1 string Directory path.
mkcd() {
  mkdir -p "$1" && cd "$1" || return 1
}
