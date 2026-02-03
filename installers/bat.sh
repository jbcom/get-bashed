#!/usr/bin/env bash
# @file bat
# @brief Installer: bat
# @description
#     Installer script for get-bashed.

INSTALL_ID="bat"
INSTALL_DEPS=""
INSTALL_DESC="bat"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_bat() {
  if command -v bat >/dev/null 2>&1; then
    return 0
  fi
  pkg_install bat
}
