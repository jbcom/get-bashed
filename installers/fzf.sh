#!/usr/bin/env bash
# @file fzf
# @brief Installer: fzf
# @description
#     Installer script for get-bashed.

INSTALL_ID="fzf"
INSTALL_DEPS=""
INSTALL_DESC="fzf"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    return 0
  fi
  pkg_install fzf
}
