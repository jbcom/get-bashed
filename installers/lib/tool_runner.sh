# @description Install a component using available methods.
# @arg $1 string Action (enable|disable|install).
# @arg $2 string Term to resolve/install.
component_install() {
  local action="$1"
  local term="$2"
  local prefix target target_dir
  local tmp_dir cmd

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

  if _using_asdf && [[ -n "${GET_BASHED_ASDF_DEFAULT_VERSIONS[$term]:-}" ]]; then
    install_asdf_runtime "$term"
    return $?
  fi

  if _using_brew && brew_exec install "$term"; then
    return 0
  fi
  if command -v apt-get >/dev/null 2>&1 && apt_install "$term"; then
    return 0
  fi
  if command -v dnf >/dev/null 2>&1 && dnf_install "$term"; then
    return 0
  fi
  if command -v yum >/dev/null 2>&1 && yum_install "$term"; then
    return 0
  fi
  if command -v pacman >/dev/null 2>&1 && pacman_install "$term"; then
    return 0
  fi

  if [[ -n "${GET_BASHED_GIT_SOURCES[$term]:-}" ]] && _using_git; then
    prefix="$(_tool_prefix)"
    target_dir="${TOOL_TARGET_DIR[$term]:-$term}"
    target="$prefix/vendor/$target_dir"
    mkdir -p "$prefix/vendor"
    _ensure_git_checkout_at_ref "$term" "${GET_BASHED_GIT_SOURCES[$term]}" "$target" || return 1
    if [[ -n "${GET_BASHED_GIT_POST[$term]:-}" ]]; then
      (cd "$target" && sh "${GET_BASHED_GIT_POST[$term]}") || return 1
    fi
    return 0
  fi

  if [[ -n "${GET_BASHED_CURL_SOURCES[$term]:-}" ]] && _using_curl; then
    tmp_dir="$(mktemp -d)"
    if ! curl -fsSL "${GET_BASHED_CURL_SOURCES[$term]}" -o "$tmp_dir/install.sh"; then
      rm -rf "$tmp_dir"
      echo "Failed to download installer for $term" >&2
      return 1
    fi
    cmd="${GET_BASHED_CURL_CMD[$term]:-bash}"
    if ! "$cmd" "$tmp_dir/install.sh"; then
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
  local handler bin methods method
  local url prefix target target_dir tmp_dir cmd

  _ensure_tools_loaded

  handler="${TOOL_HANDLER[$id]:-}"
  if [[ -n "$handler" ]]; then
    "$handler" "$id"
    return $?
  fi

  bin="${TOOL_BIN[$id]:-}"
  if [[ -n "$bin" ]] && command -v "$bin" >/dev/null 2>&1; then
    return 0
  fi

  methods="${TOOL_METHODS[$id]:-}"
  if [[ -z "$methods" ]]; then
    echo "No install methods defined for $id" >&2
    return 1
  fi

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
        local pip_spec
        _using_pip || continue
        pip_spec="$(pip_package_spec "$id")"
        python3 -m pip install --prefix "$(_tool_prefix)" "$pip_spec" && return 0
        ;;
      pipx)
        pipx_install "$id" && return 0
        ;;
      git)
        _using_git || continue
        url="${TOOL_GIT_URL[$id]:-}"
        [[ -n "$url" ]] || continue
        prefix="$(_tool_prefix)"
        target_dir="${TOOL_TARGET_DIR[$id]:-$id}"
        target="$prefix/vendor/$target_dir"
        mkdir -p "$prefix/vendor"
        _ensure_git_checkout_at_ref "$id" "$url" "$target" && return 0
        ;;
      curl)
        _using_curl || continue
        url="${TOOL_CURL_URL[$id]:-}"
        [[ -n "$url" ]] || continue
        tmp_dir="$(mktemp -d)"
        if ! curl -fsSL "$url" -o "$tmp_dir/install.sh"; then
          rm -rf "$tmp_dir"
          return 1
        fi
        cmd="${TOOL_CURL_CMD[$id]:-bash}"
        if ! "$cmd" "$tmp_dir/install.sh"; then
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
