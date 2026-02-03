#!/usr/bin/env bash
# @file shellcheck
# @brief Installer: shellcheck
# @description
#     Installer script for get-bashed.

INSTALL_ID="shellcheck"
INSTALL_DEPS=""
INSTALL_DESC="ShellCheck"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_shellcheck() {
  if command -v shellcheck >/dev/null 2>&1; then
    return 0
  fi
  pkg_install shellcheck
}
