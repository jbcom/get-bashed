#!/usr/bin/env bash
# @file jq
# @brief Installer: jq
# @description
#     Installer script for get-bashed.

INSTALL_ID="jq"
INSTALL_DEPS=""
INSTALL_DESC="jq"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  pkg_install jq
}
