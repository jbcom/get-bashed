#!/usr/bin/env bash
# @file rg
# @brief Installer: rg
# @description
#     Installer script for get-bashed.

INSTALL_ID="rg"
INSTALL_DEPS=""
INSTALL_DESC="ripgrep"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_rg() {
  if command -v rg >/dev/null 2>&1; then
    return 0
  fi
  pkg_install ripgrep rg
}
