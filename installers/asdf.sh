#!/usr/bin/env bash
# @file asdf
# @brief Installer: asdf
# @description
#     Installer script for get-bashed.

INSTALL_ID="asdf"
INSTALL_DEPS="brew"
INSTALL_DESC="asdf version manager"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_asdf() {
  if _using_asdf; then
    return 0
  fi

  if _using_brew; then
    brew install asdf
    return 0
  fi

  if _using_git; then
    if [[ -d "$HOME/.asdf" ]]; then
      return 0
    fi
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf"
    if git -C "$HOME/.asdf" describe --tags --abbrev=0 >/dev/null 2>&1; then
      local tag
      tag="$(git -C "$HOME/.asdf" describe --tags --abbrev=0)"
      git -C "$HOME/.asdf" checkout "$tag" || true
    fi
    return 0
  fi

  echo "asdf install requires Homebrew or git." >&2
  return 1
}
