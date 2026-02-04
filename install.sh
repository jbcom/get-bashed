#!/bin/sh
# Minimal POSIX bootstrap. Installs/locates bash and hands off to the bash installer.

set -eu

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

ensure_bash() {
  brew_bin=""
  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
  elif [ -x "/opt/homebrew/bin/brew" ]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [ -x "/usr/local/bin/brew" ]; then
    brew_bin="/usr/local/bin/brew"
  fi

  if command -v bash >/dev/null 2>&1; then
    return 0
  fi
  if command -v /opt/homebrew/bin/bash >/dev/null 2>&1; then
    return 0
  fi
  if command -v /usr/local/bin/bash >/dev/null 2>&1; then
    return 0
  fi

  if [ -n "$brew_bin" ]; then
    "$brew_bin" install bash
    return 0
  fi
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y bash
    return 0
  fi
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y bash
    return 0
  fi
  if command -v yum >/dev/null 2>&1; then
    sudo yum install -y bash
    return 0
  fi
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm bash
    return 0
  fi

  fail "Bash is required but was not found or installed. Install bash and re-run."
}

ensure_bash

if [ -x "/opt/homebrew/bin/bash" ]; then
  exec /opt/homebrew/bin/bash "$(dirname "$0")/install.bash" "$@"
fi
if [ -x "/usr/local/bin/bash" ]; then
  exec /usr/local/bin/bash "$(dirname "$0")/install.bash" "$@"
fi
exec bash "$(dirname "$0")/install.bash" "$@"
