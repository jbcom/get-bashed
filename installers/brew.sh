#!/usr/bin/env bash
# @file brew
# @brief Installer: brew
# @description
#     Installer script for get-bashed.

INSTALL_ID="brew"
INSTALL_DEPS=""
INSTALL_DESC="Homebrew/Linuxbrew installer"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_brew() {
  if _using_brew; then
    return 0
  fi

  if _using_curl; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "curl is required to install Homebrew." >&2
    return 1
  fi
}
