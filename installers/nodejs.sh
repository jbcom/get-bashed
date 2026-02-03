#!/usr/bin/env bash
# @file nodejs
# @brief Installer: nodejs
# @description
#     Installer script for get-bashed.

INSTALL_ID="nodejs"
INSTALL_DEPS="asdf"
INSTALL_DESC="Node.js (asdf preferred)"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_nodejs() {
  if command -v node >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    asdf_install_plugin nodejs || true
    latest_version="$(asdf latest nodejs 2>/dev/null || true)"
    if [[ -n "$latest_version" ]]; then
      asdf install nodejs "$latest_version"
      asdf set --home nodejs "$latest_version"
      return 0
    fi
    echo "Failed to resolve latest Node.js version via asdf." >&2
    return 1
  fi

  pkg_install node
}
