#!/usr/bin/env bash
# @file ci-setup
# @brief CI setup using get-bashed installers.
# @description
#     Detects GitHub Actions runner environment and installs tools into
#     a writable prefix via get-bashed.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

append_ci_path() {
  local path_entry="$1"

  [[ -n "$path_entry" && -d "$path_entry" ]] || return 0
  case ":$PATH:" in
    *":$path_entry:"*) ;;
    *) export PATH="$path_entry:$PATH" ;;
  esac

  if [[ -n "${GITHUB_PATH:-}" ]]; then
    printf '%s\n' "$path_entry" >> "$GITHUB_PATH"
  fi
}

find_brew_bin() {
  local candidate

  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -x "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done

  return 1
}

# Prefer RUNNER_TEMP, then RUNNER_TOOL_CACHE, then /tmp
PREFIX="${GET_BASHED_HOME:-${RUNNER_TEMP:-${RUNNER_TOOL_CACHE:-/tmp}}/get-bashed}"
export GET_BASHED_HOME="$PREFIX"
export PATH="$GET_BASHED_HOME/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"
export HOMEBREW_NO_INSTALL_CLEANUP="${HOMEBREW_NO_INSTALL_CLEANUP:-1}"
export HOMEBREW_NO_ENV_HINTS="${HOMEBREW_NO_ENV_HINTS:-1}"

INSTALLS="${1:-shdoc,actionlint,shellcheck,bashate}"

"$ROOT_DIR/install.sh" --auto --install "$INSTALLS"

append_ci_path "$GET_BASHED_HOME/bin"

if brew_bin="$(find_brew_bin)"; then
  brew_prefix="$("$brew_bin" --prefix 2>/dev/null || true)"
  append_ci_path "$brew_prefix/bin"
  append_ci_path "$brew_prefix/sbin"
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'GET_BASHED_HOME=%s\n' "$GET_BASHED_HOME" >> "$GITHUB_ENV"
fi

echo "CI tools installed to $GET_BASHED_HOME"
