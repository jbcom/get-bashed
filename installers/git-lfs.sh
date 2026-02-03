#!/usr/bin/env bash
# @file git-lfs
# @brief Installer: git-lfs
# @description
#     Installer script for get-bashed.

INSTALL_ID="git_lfs"
INSTALL_DEPS=""
INSTALL_DESC="Git LFS"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_git_lfs() {
  if command -v git-lfs >/dev/null 2>&1; then
    return 0
  fi
  pkg_install git-lfs git-lfs
}
