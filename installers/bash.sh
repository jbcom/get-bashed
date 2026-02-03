#!/usr/bin/env bash
# @file bash
# @brief Installer: bash
# @description
#     Installer script for get-bashed.

INSTALL_ID="bash"
INSTALL_DEPS=""
INSTALL_DESC="Latest GNU Bash"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_bash() {
  if command -v bash >/dev/null 2>&1; then
    local major
    major="$(bash -c 'echo ${BASH_VERSINFO[0]:-0}' 2>/dev/null || echo 0)"
    if [[ "$major" -ge 4 ]]; then
      return 0
    fi
  fi
  pkg_install bash bash bash bash
}
