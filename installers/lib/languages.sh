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
    _ensure_git_checkout_at_ref "asdf" "${GET_BASHED_GIT_SOURCES["asdf"]}" "$HOME/.asdf" || return 1
    return 0
  fi

  echo "asdf install requires Homebrew or git." >&2
  return 1
}

# @description Install a pinned asdf runtime version.
# @arg $1 string Plugin name.
install_asdf_runtime() {
  local plugin="$1"
  local version repo

  version="$(asdf_default_version "$plugin")"
  repo="$(asdf_plugin_source "$plugin")"

  if [[ -z "$version" ]]; then
    echo "No pinned asdf version configured for ${plugin}." >&2
    return 1
  fi

  asdf_install_plugin "$plugin" "$repo" || return 1
  asdf install "$plugin" "$version" || return 1
  asdf set --home "$plugin" "$version"
}

# @description Install Java (handler).
install_java() {
  if command -v java >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    install_asdf_runtime java
    return $?
  fi

  pkg_install openjdk
}

# @description Install Node.js (handler).
install_nodejs() {
  if command -v node >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    install_asdf_runtime nodejs
    return $?
  fi

  pkg_install node
}

# @description Install Python (handler).
install_python() {
  if command -v python3 >/dev/null 2>&1; then
    return 0
  fi

  if _using_asdf; then
    install_asdf_runtime python
    return $?
  fi

  pkg_install python3 python3 python3 python3 python3
}
