#!/usr/bin/env bash
# @file bats
# @brief Installer: bats
# @description
#     Installer script for get-bashed.

INSTALL_ID="bats"
INSTALL_DEPS=""
INSTALL_DESC="Bats (bash testing)"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_bats() {
  if command -v bats >/dev/null 2>&1; then
    return 0
  fi
  pkg_install bats-core bats
}
