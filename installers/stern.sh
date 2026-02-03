#!/usr/bin/env bash
# @file stern
# @brief Installer: stern
# @description
#     Installer script for get-bashed.

INSTALL_ID="stern"
INSTALL_DEPS=""
INSTALL_DESC="stern"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_stern() {
  if command -v stern >/dev/null 2>&1; then
    return 0
  fi
  pkg_install stern
}
