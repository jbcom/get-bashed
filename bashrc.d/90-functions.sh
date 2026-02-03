# @file 90-functions
# @brief get-bashed module: 90-functions
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Quick extractor
ex () {
  local f="$1"
  [[ -f "$f" ]] || { echo "'$f' is not a valid file"; return 1; }
  case "$f" in
    *.tar.bz2) tar xjf "$f" ;;
    *.tar.gz)  tar xzf "$f" ;;
    *.bz2)     bunzip2 "$f" ;;
    *.rar)     unrar x "$f" ;;
    *.gz)      gunzip "$f" ;;
    *.tar)     tar xf "$f" ;;
    *.tbz2)    tar xjf "$f" ;;
    *.tgz)     tar xzf "$f" ;;
    *.zip)     unzip "$f" ;;
    *.Z)       uncompress "$f" ;;
    *.7z)      7z x "$f" ;;
    *)         echo "'$f' cannot be extracted via ex()" ;;
  esac
}
