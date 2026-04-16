get_deps() {
  local id="$1"
  local deps opt flag dep

  _ensure_tools_loaded
  deps="${TOOL_DEPS[$id]:-}"
  opt="${TOOL_OPT_DEPS[$id]:-}"

  if [[ -n "$opt" ]]; then
    IFS=',' read -r -a _opt_specs <<<"$opt"
    for spec in "${_opt_specs[@]}"; do
      flag="${spec%%:*}"
      dep="${spec#*:}"
      if [[ -n "${!flag:-}" && "${!flag}" != "0" ]]; then
        deps="$(append_csv_unique "$deps" "$dep")"
      fi
    done
  fi

  echo "$deps"
}

run_selected_installers() {
  local -A install_in_progress=()
  local -A install_done=()
  local id

  is_done() {
    local current_id="$1"
    [[ "${install_done[$current_id]:-}" == "1" ]]
  }

  mark_done() {
    local current_id="$1"
    install_done["$current_id"]=1
  }

  run_install() {
    local current_id="$1"
    local deps dep

    if is_done "$current_id"; then
      return 0
    fi

    if [[ "${install_in_progress[$current_id]:-}" == "1" ]]; then
      echo "Circular dependency detected while installing $current_id" >&2
      return 1
    fi

    install_in_progress["$current_id"]=1
    deps="$(get_deps "$current_id")"
    if [[ -n "$deps" ]]; then
      for dep in $(split_csv "$deps"); do
        run_install "$dep" || return 1
      done
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "would install: $current_id"
    else
      install_tool "$current_id"
    fi

    unset "install_in_progress[$current_id]"
    mark_done "$current_id"
  }

  [[ -n "$INSTALLS" ]] || return 0

  for id in $(split_csv "$INSTALLS"); do
    run_install "$id"
  done
}
