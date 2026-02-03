#!/usr/bin/env bash
# @file vimrc
# @brief Installer: vimrc (amix)
# @description
#     Installer script for get-bashed.

INSTALL_ID="vimrc"
INSTALL_DEPS="git"
INSTALL_DESC="amix/vimrc (awesome vimrc)"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_vimrc() {
  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  local target="$prefix/vendor/vimrc"
  if [[ -d "$target/.git" ]]; then
    return 0
  fi
  mkdir -p "$prefix/vendor"
  git clone --depth=1 https://github.com/amix/vimrc.git "$target"
  case "${GET_BASHED_VIMRC_MODE:-awesome}" in
    basic)
      sh "$target/install_basic_vimrc.sh"
      ;;
    *)
      sh "$target/install_awesome_vimrc.sh"
      ;;
  esac
}
