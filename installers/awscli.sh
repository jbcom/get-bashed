#!/usr/bin/env bash
# @file awscli
# @brief Installer: awscli
# @description
#     Installer script for get-bashed.

INSTALL_ID="awscli"
INSTALL_DEPS=""
INSTALL_DESC="AWS CLI"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_awscli() {
  if command -v aws >/dev/null 2>&1; then
    return 0
  fi
  pkg_install awscli awscli
}
