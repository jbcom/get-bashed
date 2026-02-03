#!/usr/bin/env bash
# @file fd
# @brief Installer: fd
# @description
#     Installer script for get-bashed.

INSTALL_ID="fd"
INSTALL_DEPS=""
INSTALL_DESC="fd"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_fd() {
  if command -v fd >/dev/null 2>&1; then
    return 0
  fi
  pkg_install fd
}
