#!/usr/bin/env bash
# @file java
# @brief Installer: java
# @description
#     Installer script for get-bashed.

INSTALL_ID="java"
INSTALL_DEPS="asdf"
INSTALL_DESC="Java (asdf preferred)"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_java() {
  if command -v java >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    asdf_install_plugin java https://github.com/halcyon/asdf-java.git || true
    latest_version="$(asdf latest java 2>/dev/null || true)"
    if [[ -n "$latest_version" ]]; then
      asdf install java "$latest_version"
      asdf set --home java "$latest_version"
      return 0
    fi
    echo "Failed to resolve latest Java version via asdf." >&2
    return 1
  fi

  pkg_install openjdk
}
