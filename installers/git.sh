#!/usr/bin/env bash
# @file git
# @brief Installer: git
# @description
#     Installer script for get-bashed.

INSTALL_ID="git"
INSTALL_DEPS=""
INSTALL_DESC="git"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_git() {
  if _using_git; then
    return 0
  fi
  pkg_install git
}
