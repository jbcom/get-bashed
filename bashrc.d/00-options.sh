#!/usr/bin/env bash
# @file 00-options
# @brief get-bashed module: 00-options
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Shell options, history, editor
shopt -s histappend checkwinsize cmdhist lithist autocd cdspell checkjobs expand_aliases
HISTIGNORE="&:history:ls:ls *:ps:ps -A:[bf]g:exit:${HISTIGNORE}"

# Editor default (respect existing)
: "${EDITOR:=vim}"
export EDITOR

# macOS: silence legacy bash warning + raise soft fd limit
if [[ "$(uname -s)" == "Darwin" ]]; then
  export BASH_SILENCE_DEPRECATION_WARNING=1
  ulimit -n 524288 2>/dev/null || true
fi

# Misc
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
