#!/usr/bin/env bash

# @internal
_using_asdf() { command -v asdf >/dev/null 2>&1; }

# @internal
_brew_bin() {
  local candidate
  local -a candidates=()

  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi

  if [[ -n "${GET_BASHED_BREW_BIN_CANDIDATES:-}" ]]; then
    # shellcheck disable=SC2206
    candidates=(${GET_BASHED_BREW_BIN_CANDIDATES})
  else
    candidates=(/opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew)
  fi

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

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
_using_curl() { command -v curl >/dev/null 2>&1; }

# @internal
_using_pipx() { command -v pipx >/dev/null 2>&1; }

# @internal
_using_pip() { command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; }

# @internal
_tools_loaded() { [[ -n "${TOOL_IDS[*]:-}" ]]; }

# @internal
_ensure_tools_loaded() {
  local repo_dir

  _tools_loaded && return 0

  repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  # shellcheck disable=SC1090,SC1091
  source "$repo_dir/installers/tools.sh"
}

# @internal
_auto_approved() { [[ "${GET_BASHED_AUTO_APPROVE:-0}" == "1" ]]; }

# @internal
_tool_prefix() { echo "${GET_BASHED_HOME:-$HOME/.get-bashed}"; }

# @internal
_git_ref_for() {
  local id="$1"
  echo "${GET_BASHED_GIT_REFS[$id]:-}"
}

# @internal
_clone_at_ref() {
  local id="$1"
  local url="$2"
  local target="$3"
  local ref

  ref="$(_git_ref_for "$id")"
  rm -rf "$target"

  if ! git clone "$url" "$target" >/dev/null 2>&1; then
    echo "Failed to clone $id from $url" >&2
    return 1
  fi

  if [[ -n "$ref" ]] && ! git -C "$target" checkout "$ref" >/dev/null 2>&1; then
    echo "Failed to checkout $id ref $ref" >&2
    return 1
  fi
}

# @internal
_git_repo_matches_ref() {
  local id="$1"
  local url="$2"
  local target="$3"
  local ref remote head expected

  [[ -d "$target/.git" ]] || return 1

  remote="$(git -C "$target" remote get-url origin 2>/dev/null || true)"
  [[ "$remote" == "$url" ]] || return 1

  ref="$(_git_ref_for "$id")"
  [[ -n "$ref" ]] || return 0

  head="$(git -C "$target" rev-parse HEAD 2>/dev/null || true)"
  expected="$(git -C "$target" rev-parse "${ref}^{commit}" 2>/dev/null || git -C "$target" rev-parse "$ref" 2>/dev/null || true)"
  [[ -n "$expected" && "$head" == "$expected" ]]
}

# @internal
_ensure_git_checkout_at_ref() {
  local id="$1"
  local url="$2"
  local target="$3"

  if _git_repo_matches_ref "$id" "$url" "$target"; then
    return 0
  fi

  _clone_at_ref "$id" "$url" "$target"
}

# @description Return the SHA-256 digest for a file.
# @arg $1 string File path.
# @exitcode 0 If a checksum tool is available.
# @exitcode 1 If no checksum tool is available.
sha256_file() {
  local file="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "sha256sum or shasum is required to verify $file" >&2
    return 1
  fi
}
