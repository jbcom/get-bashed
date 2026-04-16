#!/bin/sh
# Minimal POSIX bootstrap. Installs or locates Bash 4+ and hands off to install.bash.

set -eu

BOOTSTRAP_SOURCES_FILE="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)/installers/bootstrap_sources.sh"
if [ -r "$BOOTSTRAP_SOURCES_FILE" ]; then
  # shellcheck disable=SC1090,SC1091
  . "$BOOTSTRAP_SOURCES_FILE"
fi

: "${GET_BASHED_BOOTSTRAP_BREW_URL:=https://raw.githubusercontent.com/Homebrew/install/de0b0bddf1c78731dcd16d953b2f5d29d070e229/install.sh}"
: "${GET_BASHED_BOOTSTRAP_BREW_CMD:=/bin/bash}"
: "${GET_BASHED_BOOTSTRAP_REPO_ARCHIVE_URL:=https://github.com/jbcom/get-bashed/archive/22eff2b26037a7db4548e3996e587173cf2aa053.tar.gz}"

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

script_dir() {
  CDPATH='' cd -- "$(dirname "$0")" && pwd
}

has_repo_tree() {
  repo_dir="$1"
  [ -r "$repo_dir/install.bash" ] || return 1
  [ -r "$repo_dir/installers/_helpers.sh" ] || return 1
}

bash_major_version() {
  candidate="$1"
  # shellcheck disable=SC2016
  "$candidate" -c 'printf "%s" "${BASH_VERSINFO[0]:-0}"' 2>/dev/null || printf '0'
}

is_modern_bash() {
  candidate="$1"
  [ -n "$candidate" ] || return 1
  [ -x "$candidate" ] || return 1
  major="$(bash_major_version "$candidate")"
  [ "$major" -ge 4 ]
}

find_modern_bash() {
  candidates="${GET_BASHED_BOOTSTRAP_BASH_CANDIDATES:-/opt/homebrew/bin/bash /usr/local/bin/bash /home/linuxbrew/.linuxbrew/bin/bash}"

  for candidate in $candidates; do
    if is_modern_bash "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  path_bash=""
  if command -v bash >/dev/null 2>&1; then
    path_bash="$(command -v bash)"
  fi
  if [ -n "$path_bash" ] && is_modern_bash "$path_bash"; then
    printf '%s\n' "$path_bash"
    return 0
  fi

  return 1
}

find_brew_bin() {
  candidates="${GET_BASHED_BOOTSTRAP_BREW_CANDIDATES:-/opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew}"

  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  for candidate in $candidates; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

download_bootstrap_asset() {
  url="$1"
  dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
    return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
    return 0
  fi

  return 1
}

bootstrap_repo_tree() {
  tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t get-bashed)"
  archive="$tmpdir/get-bashed.tar.gz"
  extract_dir="$tmpdir/src"
  repo_dir=""

  if ! download_bootstrap_asset "$GET_BASHED_BOOTSTRAP_REPO_ARCHIVE_URL" "$archive"; then
    rm -rf "$tmpdir"
    fail "Standalone bootstrap requires curl or wget to fetch the get-bashed sources."
  fi

  mkdir -p "$extract_dir"
  if ! tar -xzf "$archive" -C "$extract_dir"; then
    rm -rf "$tmpdir"
    fail "Failed to extract the get-bashed source archive."
  fi

  for candidate in "$extract_dir"/*; do
    if [ -d "$candidate" ] && has_repo_tree "$candidate"; then
      repo_dir="$candidate"
      break
    fi
  done

  if [ -z "$repo_dir" ]; then
    rm -rf "$tmpdir"
    fail "Fetched get-bashed sources are incomplete."
  fi

  GET_BASHED_BOOTSTRAP_TMPDIR="$tmpdir"
  printf '%s\n' "$repo_dir"
}

resolve_repo_dir() {
  current_dir="$(script_dir)"
  if has_repo_tree "$current_dir"; then
    printf '%s\n' "$current_dir"
    return 0
  fi

  bootstrap_repo_tree
}

bootstrap_homebrew() {
  tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t get-bashed)"
  installer="$tmpdir/homebrew-install.sh"

  if ! download_bootstrap_asset "$GET_BASHED_BOOTSTRAP_BREW_URL" "$installer"; then
    rm -rf "$tmpdir"
    fail "Homebrew bootstrap requires curl or wget."
  fi

  if [ "${CI:-}" = "1" ] || [ ! -t 0 ]; then
    NONINTERACTIVE=1 "$GET_BASHED_BOOTSTRAP_BREW_CMD" "$installer"
  else
    "$GET_BASHED_BOOTSTRAP_BREW_CMD" "$installer"
  fi

  rm -rf "$tmpdir"
}

ensure_modern_bash() {
  brew_bin="$(find_brew_bin 2>/dev/null || true)"

  if find_modern_bash >/dev/null 2>&1; then
    find_modern_bash
    return 0
  fi

  if [ -n "$brew_bin" ]; then
    "$brew_bin" install bash
  elif [ -n "$GET_BASHED_BOOTSTRAP_BREW_URL" ]; then
    bootstrap_homebrew
    brew_bin="$(find_brew_bin 2>/dev/null || true)"
    if [ -z "$brew_bin" ]; then
      fail "Bash 4+ is required, and Homebrew bootstrap did not produce a brew executable."
    fi
    "$brew_bin" install bash
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y bash
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y bash
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y bash
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm bash
  else
    fail "Bash 4+ is required but no supported installer was found."
  fi

  if find_modern_bash >/dev/null 2>&1; then
    find_modern_bash
    return 0
  fi

  fail "Bash 4+ is required but could not be located after installation."
}

repo_dir="$(resolve_repo_dir)"
bootstrap_bash="$(ensure_modern_bash)"
[ -n "${GET_BASHED_BOOTSTRAP_TMPDIR:-}" ] && export GET_BASHED_BOOTSTRAP_TMPDIR
exec "$bootstrap_bash" "$repo_dir/install.bash" "$@"
