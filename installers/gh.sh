#!/usr/bin/env bash
# @file gh
# @brief Installer: gh
# @description
#     Installer script for get-bashed.

INSTALL_ID="gh"
INSTALL_DEPS=""
INSTALL_DESC="GitHub CLI"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_gh() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi
  pkg_install gh
}
