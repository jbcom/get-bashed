#!/usr/bin/env bash
# @file starship
# @brief Installer: starship
# @description
#     Installer script for get-bashed.

INSTALL_ID="starship"
INSTALL_DEPS="brew"
INSTALL_DESC="Starship prompt"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_starship() {
  if command -v starship >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew install starship
  else
    echo "Starship install requires Homebrew or manual install." >&2
    return 1
  fi
}
