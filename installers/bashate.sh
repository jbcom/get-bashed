#!/usr/bin/env bash
# @file bashate
# @brief Installer: bashate
# @description
#     Installer script for get-bashed.

INSTALL_ID="bashate"
INSTALL_DEPS="pipx"
INSTALL_DESC="bashate"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_bashate() {
  if command -v bashate >/dev/null 2>&1; then
    return 0
  fi
  pipx_install bashate
}
