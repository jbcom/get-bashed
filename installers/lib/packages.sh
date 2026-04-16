# @description Run a command with auto-approval when configured.
# @arg $1 string Command name.
# @arg $2 string Optional flag to auto-approve (e.g., -y, --noconfirm).
# @arg $3 string Optional extra flag (e.g., --assume-yes).
# @arg $4 string Optional extra flag (e.g., --yes).
# @arg $5 string Optional extra flag (e.g., --confirm).
# @arg $6 string Optional extra flag (e.g., --no-confirm).
auto_exec() {
  local cmd="$1"
  shift
  local -a flags=()

  if _auto_approved; then
    while [[ $# -gt 0 ]]; do
      [[ -n "$1" ]] && flags+=("$1")
      shift
    done
  fi

  "$cmd" "${flags[@]}"
}

# @internal
apt_install() {
  sudo apt-get update
  if _auto_approved; then
    sudo apt-get install -y "$@"
  else
    sudo apt-get install "$@"
  fi
}

# @internal
dnf_install() {
  if _auto_approved; then
    sudo dnf install -y "$@"
  else
    sudo dnf install "$@"
  fi
}

# @internal
yum_install() {
  if _auto_approved; then
    sudo yum install -y "$@"
  else
    sudo yum install "$@"
  fi
}

# @internal
pacman_install() {
  if _auto_approved; then
    sudo pacman -Sy --noconfirm "$@"
  else
    sudo pacman -Sy "$@"
  fi
}

# @internal
_bash_it_available() {
  local prefix

  [[ "${GET_BASHED_USE_BASH_IT:-0}" == "1" ]] || return 1
  prefix="$(_tool_prefix)"
  [[ -r "$prefix/vendor/bash-it/bash_it.sh" ]]
}

# @internal
_bash_it_search() {
  local action="$1"
  shift
  local prefix bash_it

  prefix="$(_tool_prefix)"
  bash_it="$prefix/vendor/bash-it"
  # shellcheck disable=SC1090,SC1091
  source "$bash_it/bash_it.sh"
  NO_COLOR=1 bash-it search "$@" "--${action}"
}

# @description Install a package via available system package manager.
# @arg $1 string Brew package name.
# @arg $2 string Apt package name (optional).
# @arg $3 string Dnf package name (optional).
# @arg $4 string Yum package name (optional).
# @arg $5 string Pacman package name (optional).
# @exitcode 0 If installed.
# @exitcode 1 If no supported package manager.
pkg_install() {
  local brew_pkg="$1"
  local apt_pkg="${2:-$1}"
  local dnf_pkg="${3:-$1}"
  local yum_pkg="${4:-$1}"
  local pacman_pkg="${5:-$1}"

  if _using_brew; then
    brew_exec install "$brew_pkg"
  elif command -v apt-get >/dev/null 2>&1; then
    apt_install "$apt_pkg"
  elif command -v dnf >/dev/null 2>&1; then
    dnf_install "$dnf_pkg"
  elif command -v yum >/dev/null 2>&1; then
    yum_install "$yum_pkg"
  elif command -v pacman >/dev/null 2>&1; then
    pacman_install "$pacman_pkg"
  else
    echo "No supported package manager found for $brew_pkg" >&2
    return 1
  fi
}

# @description Return the configured pipx package spec for a tool id.
# @arg $1 string Tool id.
pipx_package_spec() {
  local pkg="$1"
  echo "${GET_BASHED_PIPX_PACKAGES[$pkg]:-$pkg}"
}

# @description Return the configured pip package spec for a tool id.
# @arg $1 string Tool id.
pip_package_spec() {
  local pkg="$1"
  echo "${GET_BASHED_PIP_PACKAGES[$pkg]:-$pkg}"
}

# @description Install a Python tool via pipx (fallback to pip).
# @arg $1 string Package name.
# @exitcode 0 If installed.
# @exitcode 1 If pipx/pip missing.
pipx_install() {
  local pkg="$1"
  local spec
  local prefix

  spec="$(pipx_package_spec "$pkg")"
  prefix="$(_tool_prefix)"

  if _using_pipx; then
    mkdir -p "$prefix/bin" "$prefix/pipx" "$prefix/share/man"
    PIPX_HOME="$prefix/pipx" \
    PIPX_BIN_DIR="$prefix/bin" \
    PIPX_MAN_DIR="$prefix/share/man" \
      pipx install "$spec"
  elif _using_pip; then
    python3 -m pip install --prefix "$prefix" "$spec"
  else
    echo "pipx or pip is required to install $pkg" >&2
    return 1
  fi
}
