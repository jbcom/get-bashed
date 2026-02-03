#!/usr/bin/env bash
# @file tree
# @brief Installer: tree
# @description
#     Installer script for get-bashed.

INSTALL_ID="tree"
INSTALL_DEPS=""
INSTALL_DESC="tree"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_tree() {
  if command -v tree >/dev/null 2>&1; then
    return 0
  fi
  pkg_install tree
}
