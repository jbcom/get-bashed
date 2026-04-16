#!/usr/bin/env bash

# @description Check if an asdf plugin is installed.
# @arg $1 string Plugin name.
# @exitcode 0 If installed.
# @exitcode 1 If missing.
asdf_has_plugin() {
  local plugin="$1"
  _using_asdf || return 1
  asdf plugin list | awk '{print $1}' | grep -qx "$plugin"
}

# @internal
asdf_plugin_path() {
  local plugin="$1"
  echo "${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/$plugin"
}

# @description Return the configured asdf plugin source identifier.
# @arg $1 string Plugin name.
asdf_plugin_id() {
  local plugin="$1"
  echo "${GET_BASHED_ASDF_PLUGIN_IDS[$plugin]:-}"
}

# @description Install an asdf plugin if missing.
# @arg $1 string Plugin name.
# @arg $2 string Plugin repo (optional).
# @exitcode 0 If installed or already present.
# @exitcode 1 If asdf not available.
asdf_install_plugin() {
  local plugin="$1"
  local repo="${2:-$(asdf_plugin_source "$plugin")}"

  _using_asdf || return 1
  if ! asdf_has_plugin "$plugin"; then
    if [[ -n "$repo" ]]; then
      asdf plugin add "$plugin" "$repo" || return 1
    else
      asdf plugin add "$plugin" || return 1
    fi
  fi

  asdf_pin_plugin_ref "$plugin"
}

# @description Return the configured asdf plugin source URL.
# @arg $1 string Plugin name.
asdf_plugin_source() {
  local plugin="$1"
  echo "${GET_BASHED_ASDF_PLUGIN_SOURCES[$plugin]:-}"
}

# @description Return the configured asdf plugin git ref.
# @arg $1 string Plugin name.
asdf_plugin_ref() {
  local plugin="$1"
  local id

  id="$(asdf_plugin_id "$plugin")"
  echo "${GET_BASHED_GIT_REFS[$id]:-}"
}

# @description Pin an installed asdf plugin checkout to the configured ref.
# @arg $1 string Plugin name.
asdf_pin_plugin_ref() {
  local plugin="$1"
  local ref plugin_dir

  ref="$(asdf_plugin_ref "$plugin")"
  [[ -n "$ref" ]] || return 0

  plugin_dir="$(asdf_plugin_path "$plugin")"
  [[ -d "$plugin_dir/.git" ]] || return 0

  git -C "$plugin_dir" checkout "$ref" >/dev/null 2>&1
}

# @description Return the configured default asdf runtime version.
# @arg $1 string Plugin name.
asdf_default_version() {
  local plugin="$1"
  echo "${GET_BASHED_ASDF_DEFAULT_VERSIONS[$plugin]:-}"
}
