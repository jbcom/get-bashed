#!/usr/bin/env bash
# @file gnu-tools
# @brief Installer: gnu-tools
# @description
#     Installer script for get-bashed.

INSTALL_ID="gnu_tools"
INSTALL_DEPS="brew"
INSTALL_DESC="GNU coreutils/findutils/sed/tar"
INSTALL_PLATFORMS="macos"

# @description Run installer.
# @noargs
install_gnu_tools() {
  if _using_brew; then
    brew install coreutils findutils gnu-sed gnu-tar
  else
    echo "GNU tools install requires Homebrew." >&2
    return 1
  fi
}
