#!/usr/bin/env bash
# @file shdoc
# @brief Installer: shdoc
# @description
#     Installer script for get-bashed.

INSTALL_ID="shdoc"
INSTALL_DEPS=""
INSTALL_DESC="shdoc (shell script doc generator)"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_shdoc() {
  if command -v shdoc >/dev/null 2>&1; then
    return 0
  fi
  if pkg_install shdoc; then
    return 0
  fi

  if command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm shdoc-git && return 0
  elif command -v paru >/dev/null 2>&1; then
    paru -S --noconfirm shdoc-git && return 0
  fi

  echo "shdoc is not available via the detected package manager." >&2
  echo "Attempting local install to GET_BASHED_HOME/bin without sudo." >&2

  _using_git || { echo "git is required to build shdoc." >&2; return 1; }
  pkg_install gawk gawk gawk gawk || true
  pkg_install make make make make || true

  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  local bindir="$prefix/bin"
  mkdir -p "$bindir"

  # shdoc requires bash 4+ for ;;& case labels
  local bash_bin
  bash_bin="$(command -v bash)"
  local bash_major
  bash_major="$("$bash_bin" -c 'echo ${BASH_VERSINFO[0]:-0}' 2>/dev/null || echo 0)"
  if [[ "$bash_major" -lt 4 ]] && _using_brew; then
    brew install bash || true
    if [[ -x "/opt/homebrew/bin/bash" ]]; then
      bash_bin="/opt/homebrew/bin/bash"
    elif [[ -x "/usr/local/bin/bash" ]]; then
      bash_bin="/usr/local/bin/bash"
    fi
  fi

  tmp_dir="$(mktemp -d)"
  git clone --recursive https://github.com/reconquest/shdoc "$tmp_dir/shdoc"
  "$bash_bin" -lc "cd \"$tmp_dir/shdoc\" && make install PREFIX=\"$prefix\" BINDIR=\"$bindir\"" || {
    echo "Failed to install shdoc locally. See https://github.com/reconquest/shdoc" >&2
    rm -rf "$tmp_dir"
    return 1
  }
  rm -rf "$tmp_dir"
}
