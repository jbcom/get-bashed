#!/usr/bin/env bash
# @file curl
# @brief Installer: curl
# @description
#     Installer script for get-bashed.

INSTALL_ID="curl"
INSTALL_DEPS=""
INSTALL_DESC="curl"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_curl() {
  if command -v curl >/dev/null 2>&1; then
    return 0
  fi
  pkg_install curl
}
