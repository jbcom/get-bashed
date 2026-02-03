#!/usr/bin/env bash
# @file wget
# @brief Installer: wget
# @description
#     Installer script for get-bashed.

INSTALL_ID="wget"
INSTALL_DEPS=""
INSTALL_DESC="wget"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_wget() {
  if command -v wget >/dev/null 2>&1; then
    return 0
  fi
  pkg_install wget
}
