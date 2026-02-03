#!/usr/bin/env bash
# @file asdf
# @brief Installer: asdf
# @description
#     Installer script for get-bashed.

INSTALL_ID="asdf"
INSTALL_DEPS="brew"
INSTALL_DESC="asdf version manager"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_asdf() {
  if _using_asdf; then
    return 0
  fi

  if _using_brew; then
    brew install asdf
  else
    echo "asdf install requires Homebrew on macOS or a supported package manager." >&2
    return 1
  fi
}
