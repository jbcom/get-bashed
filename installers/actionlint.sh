#!/usr/bin/env bash
# @file actionlint
# @brief Installer: actionlint
# @description
#     Installer script for get-bashed.

INSTALL_ID="actionlint"
INSTALL_DEPS=""
INSTALL_DESC="actionlint"
INSTALL_PLATFORMS="macos,linux,wsl"

# @description Run installer.
# @noargs
install_actionlint() {
  if command -v actionlint >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew install actionlint && return 0
  fi
  if command -v apt-get >/dev/null 2>&1; then
    if apt_install actionlint; then
      return 0
    fi
  fi

  if ! _using_curl; then
    echo "curl is required to install actionlint" >&2
    return 1
  fi

  # Fallback: download latest release binary
  local tag version os arch url tmp_dir
  tag="$(python3 - <<'PY'
import json
import urllib.request
u = 'https://api.github.com/repos/rhysd/actionlint/releases/latest'
print(json.load(urllib.request.urlopen(u))['tag_name'])
PY
)"
  version="${tag#v}"
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
  esac

  if [[ "$os" == "darwin" ]]; then
    os="darwin"
  elif [[ "$os" == "linux" ]]; then
    os="linux"
  else
    echo "Unsupported OS for actionlint: $os" >&2
    return 1
  fi

  url="https://github.com/rhysd/actionlint/releases/download/${tag}/actionlint_${version}_${os}_${arch}.tar.gz"
  tmp_dir="$(mktemp -d)"
  curl -fsSL "$url" -o "$tmp_dir/actionlint.tgz"
  tar -xzf "$tmp_dir/actionlint.tgz" -C "$tmp_dir"
  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  mkdir -p "$prefix/bin"
  mv "$tmp_dir/actionlint" "$prefix/bin/actionlint"
  chmod +x "$prefix/bin/actionlint"
  rm -rf "$tmp_dir"
}
