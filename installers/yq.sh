#!/usr/bin/env bash
# @file yq
# @brief Installer: yq
# @description
#     Installer script for get-bashed.

INSTALL_ID="yq"
INSTALL_DEPS=""
INSTALL_DESC="yq"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_yq() {
  if command -v yq >/dev/null 2>&1; then
    return 0
  fi
  pkg_install yq
}
