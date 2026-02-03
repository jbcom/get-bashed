#!/usr/bin/env bash
# bashate:ignore=E003,E006
# @file installers-helpers
# @brief Shared helpers for installers.
# @description
#     Provides platform detection and package manager helpers used by
#     installer scripts.

# @internal
_using_asdf() { command -v asdf >/dev/null 2>&1; }

# @internal
_brew_bin() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    echo "/opt/homebrew/bin/brew"
    return 0
  fi
  if [[ -x "/usr/local/bin/brew" ]]; then
    echo "/usr/local/bin/brew"
    return 0
  fi
  return 1
}

# @internal
_using_brew() { _brew_bin >/dev/null 2>&1; }

# @internal
brew_exec() {
  local brew_bin
  brew_bin="$(_brew_bin)" || return 1
  "$brew_bin" "$@"
}

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

# @internal
_tools_loaded() { [[ -n "${TOOL_IDS[*]:-}" ]]; }

# @internal
_ensure_tools_loaded() {
  _tools_loaded && return 0
  local repo_dir
  repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  # shellcheck disable=SC1090
  source "$repo_dir/installers/tools.sh"
}

# @internal
_auto_approved() { [[ "${GET_BASHED_AUTO_APPROVE:-0}" == "1" ]]; }

# @description Run a command with auto-approval when configured.
# @arg $1 string Command name.
# @arg $2 string Optional flag to auto-approve (e.g., -y, --noconfirm).
# @arg $3 string Optional extra flag (e.g., --assume-yes).
# @arg $4 string Optional extra flag (e.g., --yes).
# @arg $5 string Optional extra flag (e.g., --confirm).
# @arg $6 string Optional extra flag (e.g., --no-confirm).
auto_exec() {
  local cmd="$1"; shift
  local -a flags=()
  if _auto_approved; then
    while [[ $# -gt 0 ]]; do
      [[ -n "$1" ]] && flags+=("$1")
      shift
    done
  else
    while [[ $# -gt 0 ]]; do shift; done
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
    if brew_exec install "$term"; then
      return 0
    fi
  fi

  if command -v apt-get >/dev/null 2>&1; then
    if apt_install "$term"; then
      return 0
    fi
  elif command -v dnf >/dev/null 2>&1; then
    if dnf_install "$term"; then
      return 0
    fi
  elif command -v yum >/dev/null 2>&1; then
    if yum_install "$term"; then
      return 0
    fi
  elif command -v pacman >/dev/null 2>&1; then
    if pacman_install "$term"; then
      return 0
    fi
  fi

  if [[ -n "${GET_BASHED_GIT_SOURCES[$term]:-}" ]] && _using_git; then
    local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
    local target="$prefix/vendor/$term"
    mkdir -p "$prefix/vendor"
    if ! git clone --depth=1 "${GET_BASHED_GIT_SOURCES[$term]}" "$target"; then
      echo "Failed to clone $term" >&2
      return 1
    fi
    if [[ -n "${GET_BASHED_GIT_POST[$term]:-}" ]]; then
      (cd "$target" && sh "${GET_BASHED_GIT_POST[$term]}") || return 1
    fi
    return 0
  fi

  if [[ -n "${GET_BASHED_CURL_SOURCES[$term]:-}" ]] && _using_curl; then
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    if ! curl -fsSL "${GET_BASHED_CURL_SOURCES[$term]}" -o "$tmp_dir/install.sh"; then
      rm -rf "$tmp_dir"
      echo "Failed to download installer for $term" >&2
      return 1
    fi
    local cmd="${GET_BASHED_CURL_CMD[$term]:-bash}"
    if ! $cmd "$tmp_dir/install.sh"; then
      rm -rf "$tmp_dir"
      return 1
    fi
    rm -rf "$tmp_dir"
    return 0
  fi

  echo "No installation method found for: $term" >&2
  return 1
}

# @description Install a tool from the tools registry.
# @arg $1 string Tool id.
install_tool() {
  local id="$1"
  _ensure_tools_loaded

  local handler="${TOOL_HANDLER[$id]:-}"
  if [[ -n "$handler" ]]; then
    "$handler" "$id"
    return $?
  fi

  local bin="${TOOL_BIN[$id]:-}"
  if [[ -n "$bin" ]] && command -v "$bin" >/dev/null 2>&1; then
    return 0
  fi

  local methods="${TOOL_METHODS[$id]:-}"
  if [[ -z "$methods" ]]; then
    echo "No install methods defined for $id" >&2
    return 1
  fi

  local method
  IFS=',' read -r -a _methods <<<"$methods"
  for method in "${_methods[@]}"; do
    case "$method" in
      brew)
        _using_brew || continue
        brew_exec install "${TOOL_BREW[$id]:-$id}" && return 0
        ;;
      apt)
        command -v apt-get >/dev/null 2>&1 || continue
        apt_install "${TOOL_APT[$id]:-$id}" && return 0
        ;;
      dnf)
        command -v dnf >/dev/null 2>&1 || continue
        dnf_install "${TOOL_DNF[$id]:-$id}" && return 0
        ;;
      yum)
        command -v yum >/dev/null 2>&1 || continue
        yum_install "${TOOL_YUM[$id]:-$id}" && return 0
        ;;
      pacman)
        command -v pacman >/dev/null 2>&1 || continue
        pacman_install "${TOOL_PACMAN[$id]:-$id}" && return 0
        ;;
      pip)
        _using_pip || continue
        python3 -m pip install --user "${id}" && return 0
        ;;
      pipx)
        pipx_install "${id}" && return 0
        ;;
      git)
        _using_git || continue
        local url="${TOOL_GIT_URL[$id]:-}"
        [[ -n "$url" ]] || continue
        local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
        local target="$prefix/vendor/$id"
        if [[ -d "$target/.git" ]]; then
          return 0
        fi
        mkdir -p "$prefix/vendor"
        git clone --depth=1 "$url" "$target" && return 0
        ;;
      curl)
        _using_curl || continue
        local url="${TOOL_CURL_URL[$id]:-}"
        [[ -n "$url" ]] || continue
        local tmp_dir
        tmp_dir="$(mktemp -d)"
        if ! curl -fsSL "$url" -o "$tmp_dir/install.sh"; then
          rm -rf "$tmp_dir"
          return 1
        fi
        local cmd="${TOOL_CURL_CMD[$id]:-bash}"
        if ! $cmd "$tmp_dir/install.sh"; then
          rm -rf "$tmp_dir"
          return 1
        fi
        rm -rf "$tmp_dir"
        return 0
        ;;
      *)
        ;;
    esac
  done

  echo "Failed to install $id via methods: $methods" >&2
  return 1
}

# @description Install asdf (handler).
install_asdf() {
  if _using_asdf; then
    return 0
  fi

  if _using_brew; then
    brew_exec install asdf
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

# @description Install GNU tools (handler).
install_gnu_tools() {
  if _using_brew; then
    brew_exec install coreutils findutils gnu-sed gnu-tar
    return $?
  fi
  echo "GNU tools install requires Homebrew." >&2
  return 1
}

# @description Install Java (handler).
install_java() {
  if command -v java >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    asdf_install_plugin java https://github.com/halcyon/asdf-java.git || true
    local latest_version
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

# @description Install Node.js (handler).
install_nodejs() {
  if command -v node >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    asdf_install_plugin nodejs || true
    local latest_version
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

# @description Install Python (handler).
install_python() {
  if command -v python3 >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    asdf_install_plugin python || true
    local latest_version
    latest_version="$(asdf latest python 2>/dev/null || true)"
    if [[ -n "$latest_version" ]]; then
      asdf install python "$latest_version"
      asdf set --home python "$latest_version"
      return 0
    fi
    echo "Failed to resolve latest Python version via asdf." >&2
    return 1
  fi

  pkg_install python3 python3 python3 python3
}

# @description Install shdoc (handler).
install_shdoc() {
  if command -v shdoc >/dev/null 2>&1; then
    return 0
  fi
  if pkg_install shdoc; then
    return 0
  fi

  if command -v yay >/dev/null 2>&1; then
    if _auto_approved; then
      yay -S --noconfirm shdoc-git && return 0
    else
      yay -S shdoc-git && return 0
    fi
  elif command -v paru >/dev/null 2>&1; then
    if _auto_approved; then
      paru -S --noconfirm shdoc-git && return 0
    else
      paru -S shdoc-git && return 0
    fi
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
  local bash_major
  bash_major="$(bash -c 'echo ${BASH_VERSINFO[0]:-0}' 2>/dev/null || echo 0)"
  if [[ "$bash_major" -lt 4 ]] && _using_brew; then
    brew_exec install bash || true
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  git clone --recursive https://github.com/reconquest/shdoc "$tmp_dir/shdoc"
  if ! make -C "$tmp_dir/shdoc" install PREFIX="$prefix" BINDIR="$bindir"; then
    echo "Failed to install shdoc locally. See https://github.com/reconquest/shdoc" >&2
    rm -rf "$tmp_dir"
    return 1
  fi
  rm -rf "$tmp_dir"
}

# @description Install vimrc (handler).
install_vimrc() {
  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  local target="$prefix/vendor/vimrc"
  if [[ -d "$target/.git" ]]; then
    return 0
  fi
  mkdir -p "$prefix/vendor"
  if ! git clone --depth=1 https://github.com/amix/vimrc.git "$target"; then
    echo "Failed to clone vimrc repo." >&2
    return 1
  fi
  case "${GET_BASHED_VIMRC_MODE:-awesome}" in
    basic)
      sh "$target/install_basic_vimrc.sh"
      ;;
    *)
      sh "$target/install_awesome_vimrc.sh"
      ;;
  esac
}

# @description Install actionlint (handler).
install_actionlint() {
  if command -v actionlint >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew_exec install actionlint && return 0
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

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to resolve actionlint release metadata" >&2
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
  if ! curl -fsSL "$url" -o "$tmp_dir/actionlint.tgz"; then
    rm -rf "$tmp_dir"
    echo "Failed to download actionlint from $url" >&2
    return 1
  fi
  if [[ ! -s "$tmp_dir/actionlint.tgz" ]]; then
    rm -rf "$tmp_dir"
    echo "Downloaded actionlint archive is empty." >&2
    return 1
  fi
  if ! tar -xzf "$tmp_dir/actionlint.tgz" -C "$tmp_dir"; then
    rm -rf "$tmp_dir"
    echo "Failed to extract actionlint archive." >&2
    return 1
  fi
  local prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  mkdir -p "$prefix/bin"
  mv "$tmp_dir/actionlint" "$prefix/bin/actionlint"
  chmod +x "$prefix/bin/actionlint"
  rm -rf "$tmp_dir"
}
# @description Install a package via available system package manager.
# @arg $1 string Brew package name.
# @arg $2 string Apt package name (optional).
# @arg $3 string Dnf package name (optional).
# @arg $4 string Yum package name (optional).
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
    return $?
  elif command -v apt-get >/dev/null 2>&1; then
    apt_install "$apt_pkg"
    return $?
  elif command -v dnf >/dev/null 2>&1; then
    dnf_install "$dnf_pkg"
    return $?
  elif command -v yum >/dev/null 2>&1; then
    yum_install "$yum_pkg"
    return $?
  elif command -v pacman >/dev/null 2>&1; then
    pacman_install "$pacman_pkg"
    return $?
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
