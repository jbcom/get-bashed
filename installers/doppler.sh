#!/usr/bin/env bash
# @file doppler
# @brief Installer: doppler
# @description
#     Installer script for get-bashed.

INSTALL_ID="doppler"
INSTALL_DEPS="brew"
INSTALL_DESC="Doppler CLI"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_doppler() {
  if command -v doppler >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew install doppler
  else
    echo "Doppler install requires Homebrew on macOS or manual install." >&2
    return 1
  fi
}
