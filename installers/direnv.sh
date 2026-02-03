#!/usr/bin/env bash
# @file direnv
# @brief Installer: direnv
# @description
#     Installer script for get-bashed.

INSTALL_ID="direnv"
INSTALL_DEPS="brew"
INSTALL_DESC="direnv"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_direnv() {
  if command -v direnv >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew install direnv
  else
    echo "direnv install requires Homebrew or manual install." >&2
    return 1
  fi
}
