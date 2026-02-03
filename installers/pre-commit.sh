#!/usr/bin/env bash
# @file pre-commit
# @brief Installer: pre-commit
# @description
#     Installer script for get-bashed.

INSTALL_ID="pre_commit"
INSTALL_DEPS="pipx"
INSTALL_DESC="pre-commit"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_pre_commit() {
  if command -v pre-commit >/dev/null 2>&1; then
    return 0
  fi
  pipx_install pre-commit
}
