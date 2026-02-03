#!/usr/bin/env bash
# @file bash-it
# @brief Installer: bash-it
# @description
#     Installer script for get-bashed.

INSTALL_ID="bash_it"
INSTALL_DEPS="git"
INSTALL_DESC="bash-it framework"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_bash_it() {
  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  local target="$prefix/vendor/bash-it"
  if [[ -d "$target/.git" ]]; then
    return 0
  fi
  mkdir -p "$prefix/vendor"
  git clone --depth=1 https://github.com/Bash-it/bash-it.git "$target"
}
