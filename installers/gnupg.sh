#!/usr/bin/env bash
# @file gnupg
# @brief Installer: gnupg
# @description
#     Installer script for get-bashed.

INSTALL_ID="gnupg"
INSTALL_DEPS=""
INSTALL_DESC="gnupg"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_gnupg() {
  if command -v gpg >/dev/null 2>&1; then
    return 0
  fi
  pkg_install gnupg gnupg gnupg gnupg
}
