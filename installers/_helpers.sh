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

# Known install sources (git/curl)
declare -A GET_BASHED_GIT_SOURCES=(
  ["bash_it"]="https://github.com/Bash-it/bash-it.git"
  ["vimrc"]="https://github.com/amix/vimrc.git"
  ["shdoc"]="https://github.com/reconquest/shdoc"
)

declare -A GET_BASHED_GIT_POST=(
  ["vimrc"]="install_awesome_vimrc.sh"
)

declare -A GET_BASHED_CURL_SOURCES=(
  ["brew"]="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
)

declare -A GET_BASHED_CURL_CMD=(
  ["brew"]="/bin/bash"
)

# @internal
_bash_it_available() {
  [[ "${GET_BASHED_USE_BASH_IT:-0}" == "1" ]] || return 1
  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  [[ -r "$prefix/vendor/bash-it/bash_it.sh" ]]
}

# @internal
_bash_it_search() {
  local action="$1"; shift
  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  local bash_it="$prefix/vendor/bash-it"
  # shellcheck disable=SC1090
  source "$bash_it/bash_it.sh"
  NO_COLOR=1 bash-it search "$@" "--${action}"
}

# @description Install a component using available methods.
# @arg $1 string Action (enable|disable|install).
# @arg $2 string Term to resolve/install.
component_install() {
  local action="$1" term="$2"
  shift 2 || true

  if [[ "$action" == "enable" || "$action" == "disable" ]]; then
    if _bash_it_available; then
      _bash_it_search "$action" "$term" "$@"
      return 0
    fi
    action="install"
  fi

  if [[ "$action" != "install" ]]; then
    echo "Unknown action: $action" >&2
    return 1
  fi

  if _using_asdf; then
    if asdf plugin list all 2>/dev/null | awk '{print $1}' | grep -qx "$term"; then
      asdf plugin add "$term" >/dev/null 2>&1 || true
      asdf install "$term" latest
      return $?
    fi
  fi

  if _using_brew; then
    if brew install "$term"; then
      return 0
    fi
  fi

  if command -v apt-get >/dev/null 2>&1; then
    if sudo apt-get update && sudo apt-get install -y "$term"; then
      return 0
    fi
  elif command -v dnf >/dev/null 2>&1; then
    if sudo dnf install -y "$term"; then
      return 0
    fi
  elif command -v yum >/dev/null 2>&1; then
    if sudo yum install -y "$term"; then
      return 0
    fi
  elif command -v pacman >/dev/null 2>&1; then
    if sudo pacman -Sy --noconfirm "$term"; then
      return 0
    fi
  fi

  if [[ -n "${GET_BASHED_GIT_SOURCES[$term]:-}" ]] && _using_git; then
    local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
    local target="$prefix/vendor/$term"
    mkdir -p "$prefix/vendor"
    git clone --depth=1 "${GET_BASHED_GIT_SOURCES[$term]}" "$target"
    if [[ -n "${GET_BASHED_GIT_POST[$term]:-}" ]]; then
      (cd "$target" && sh "${GET_BASHED_GIT_POST[$term]}")
    fi
    return 0
  fi

  if [[ -n "${GET_BASHED_CURL_SOURCES[$term]:-}" ]] && _using_curl; then
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    curl -fsSL "${GET_BASHED_CURL_SOURCES[$term]}" -o "$tmp_dir/install.sh"
    local cmd="${GET_BASHED_CURL_CMD[$term]:-bash}"
    $cmd "$tmp_dir/install.sh"
    rm -rf "$tmp_dir"
    return 0
  fi

  echo "No installation method found for: $term" >&2
  return 1
}
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
