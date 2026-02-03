#!/usr/bin/env bash
# @file installers-helpers
# @brief Shared helpers for installers.
# @description
#     Provides platform detection and package manager helpers used by
#     installer scripts.

# @internal
_using_asdf() { command -v asdf >/dev/null 2>&1; }

# @internal
_using_brew() { command -v brew >/dev/null 2>&1; }

# @internal
_using_git() { command -v git >/dev/null 2>&1; }

# @internal
_using_system() {
  command -v apt-get >/dev/null 2>&1 || \
  command -v dnf >/dev/null 2>&1 || \
  command -v yum >/dev/null 2>&1 || \
  command -v pacman >/dev/null 2>&1
}

# @internal
_using_curl() { command -v curl >/dev/null 2>&1; }

# @internal
_using_pipx() { command -v pipx >/dev/null 2>&1; }

# @internal
_using_pip() { command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; }

# @description Install a package via available system package manager.
# @arg $1 string Brew package name.
# @arg $2 string Apt package name (optional).
# @arg $3 string Dnf package name (optional).
# @arg $4 string Yum package name (optional).
# @exitcode 0 If installed.
# @exitcode 1 If no supported package manager.
pkg_install() {
  local brew_pkg="$1" apt_pkg="${2:-$1}" dnf_pkg="${3:-$1}" yum_pkg="${4:-$1}"
  if _using_brew; then
    brew install "$brew_pkg"
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y "$apt_pkg"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "$dnf_pkg"
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y "$yum_pkg"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm "$brew_pkg"
  else
    echo "No supported package manager found for $brew_pkg" >&2
    return 1
  fi
}

# @description Check if an asdf plugin is installed.
# @arg $1 string Plugin name.
# @exitcode 0 If installed.
# @exitcode 1 If missing.
asdf_has_plugin() {
  local plugin="$1"
  _using_asdf || return 1
  asdf plugin list | awk '{print $1}' | grep -qx "$plugin"
}

# @description Install an asdf plugin if missing.
# @arg $1 string Plugin name.
# @arg $2 string Plugin repo (optional).
# @exitcode 0 If installed or already present.
# @exitcode 1 If asdf not available.
asdf_install_plugin() {
  local plugin="$1" repo="${2:-}"
  _using_asdf || return 1
  if asdf_has_plugin "$plugin"; then
    return 0
  fi
  if [[ -n "$repo" ]]; then
    asdf plugin add "$plugin" "$repo"
  else
    asdf plugin add "$plugin"
  fi
}

# @description Install a Python tool via pipx (fallback to pip).
# @arg $1 string Package name.
# @exitcode 0 If installed.
# @exitcode 1 If pipx/pip missing.
pipx_install() {
  local pkg="$1"
  if _using_pipx; then
    pipx install "$pkg"
  elif _using_pip; then
    python3 -m pip install --user "$pkg"
  else
    echo "pipx or pip is required to install $pkg" >&2
    return 1
  fi
}
