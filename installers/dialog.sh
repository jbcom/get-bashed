#!/usr/bin/env bash
# @file dialog
# @brief Installer: dialog
# @description
#     Installer script for get-bashed.

INSTALL_ID="dialog"
INSTALL_DEPS=""
INSTALL_DESC="curses dialog UI"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_dialog() {
  if command -v dialog >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew install dialog
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y dialog
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y dialog
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y dialog
  fi
}
