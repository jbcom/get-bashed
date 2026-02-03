#!/usr/bin/env bash
# @file actionlint
# @brief Installer: actionlint
# @description
#     Installer script for get-bashed.

INSTALL_ID="actionlint"
INSTALL_DEPS=""
INSTALL_DESC="actionlint"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_actionlint() {
  if command -v actionlint >/dev/null 2>&1; then
    return 0
  fi
  pkg_install actionlint
}
