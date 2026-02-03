#!/usr/bin/env bash
# @file pipx
# @brief Installer: pipx
# @description
#     Installer script for get-bashed.

INSTALL_ID="pipx"
INSTALL_DEPS=""
INSTALL_DESC="pipx"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_pipx() {
  if _using_pipx; then
    return 0
  fi

  if _using_brew; then
    brew install pipx
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y pipx
    return 0
  fi
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y pipx
    return 0
  fi
  if command -v yum >/dev/null 2>&1; then
    sudo yum install -y pipx
    return 0
  fi
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm python-pipx
    return 0
  fi

  if _using_pip; then
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath || true
    return 0
  fi

  echo "pipx install failed: no supported method" >&2
  return 1
}
