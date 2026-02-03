#!/usr/bin/env bash
# @file kubectl
# @brief Installer: kubectl
# @description
#     Installer script for get-bashed.

INSTALL_ID="kubectl"
INSTALL_DEPS=""
INSTALL_DESC="kubectl"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    return 0
  fi
  pkg_install kubectl kubectl
}
