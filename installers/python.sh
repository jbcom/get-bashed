#!/usr/bin/env bash
# @file python
# @brief Installer: python
# @description
#     Installer script for get-bashed.

INSTALL_ID="python"
INSTALL_DEPS="asdf"
INSTALL_DESC="Python (asdf preferred)"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_python() {
  if command -v python3 >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    asdf_install_plugin python || true
    latest_version="$(asdf latest python 2>/dev/null || true)"
    if [[ -n "$latest_version" ]]; then
      asdf install python "$latest_version"
      asdf set --home python "$latest_version"
      return 0
    fi
    echo "Failed to resolve latest Python version via asdf." >&2
    return 1
  fi

  pkg_install python
}
