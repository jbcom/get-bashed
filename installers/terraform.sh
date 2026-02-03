#!/usr/bin/env bash
# @file terraform
# @brief Installer: terraform
# @description
#     Installer script for get-bashed.

INSTALL_ID="terraform"
INSTALL_DEPS=""
INSTALL_DESC="Terraform"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_terraform() {
  if command -v terraform >/dev/null 2>&1; then
    return 0
  fi
  pkg_install terraform
}
