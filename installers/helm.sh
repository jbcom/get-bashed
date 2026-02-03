#!/usr/bin/env bash
# @file helm
# @brief Installer: helm
# @description
#     Installer script for get-bashed.

INSTALL_ID="helm"
INSTALL_DEPS=""
INSTALL_DESC="Helm"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_helm() {
  if command -v helm >/dev/null 2>&1; then
    return 0
  fi
  pkg_install helm
}
