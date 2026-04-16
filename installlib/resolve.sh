#!/usr/bin/env bash

# shellcheck disable=SC2153

# @description Apply a built-in profile.
# @arg $1 string Profile name.
# @exitcode 0 If applied.
# @exitcode 1 If unknown.
apply_profile() {
  local profile="$1"
  case "$profile" in
    minimal)
      GET_BASHED_GNU=0
      GET_BASHED_BUILD_FLAGS=0
      GET_BASHED_AUTO_TOOLS=0
      GET_BASHED_SSH_AGENT=0
      GET_BASHED_USE_DOPPLER=0
      ;;
    dev)
      GET_BASHED_GNU=1
      GET_BASHED_BUILD_FLAGS=1
      GET_BASHED_AUTO_TOOLS=1
      GET_BASHED_SSH_AGENT=0
      GET_BASHED_USE_DOPPLER=0
      ;;
    ops)
      GET_BASHED_GNU=1
      GET_BASHED_BUILD_FLAGS=1
      GET_BASHED_AUTO_TOOLS=1
      GET_BASHED_SSH_AGENT=1
      GET_BASHED_USE_DOPPLER=1
      ;;
    *)
      return 1
      ;;
  esac
}

# @description Apply a feature toggle.
# @arg $1 string Feature name (supports no- prefix).
# @exitcode 0 If applied.
# @exitcode 1 If unknown.
apply_feature() {
  local feature="$1"
  local enabled=1

  if [[ "$feature" == no-* ]]; then
    enabled=0
    feature="${feature#no-}"
  fi

  case "$feature" in
    gnu_over_bsd) GET_BASHED_GNU=$enabled ;;
    build_flags) GET_BASHED_BUILD_FLAGS=$enabled ;;
    auto_tools) GET_BASHED_AUTO_TOOLS=$enabled ;;
    ssh_agent) GET_BASHED_SSH_AGENT=$enabled ;;
    doppler_env) GET_BASHED_USE_DOPPLER=$enabled ;;
    bash_it)
      GET_BASHED_USE_BASH_IT=$enabled
      if [[ "$enabled" -eq 1 ]]; then
        GROUP_INSTALLS="$(append_csv_unique "$GROUP_INSTALLS" "bash_it")"
      fi
      ;;
    git_signing) GET_BASHED_GIT_SIGNING=$enabled ;;
    dev_tools)
      GROUP_INSTALLS="$(merge_csv_lists "$GROUP_INSTALLS" "rg,fd,bat,eza,fzf,jq,yq,tree,direnv,starship,nodejs,python,bash")"
      ;;
    ops_tools)
      GROUP_INSTALLS="$(merge_csv_lists "$GROUP_INSTALLS" "gh,git_lfs,terraform,awscli,kubectl,helm,stern,doppler,eza,nodejs,python,java,bash")"
      ;;
    *)
      return 1
      ;;
  esac
}

# @description Split a comma-delimited list into space-delimited output.
# @arg $1 string Comma list.
# @stdout Space-delimited items.
split_csv() {
  local value="$1"
  local IFS=','
  read -r -a _parts <<<"$value"
  printf '%s\n' "${_parts[@]}"
}

is_valid_profile() {
  case "$1" in
    minimal|dev|ops) return 0 ;;
    *) return 1 ;;
  esac
}

apply_profile_selection() {
  local profile="$1"
  local installs_var="${2:-}"
  local profile_file selected_features selected_installs feature
  local saved_features="${FEATURES:-}"
  local saved_installs="${INSTALLS:-}"

  selected_installs=""
  profile_file="$REPO_DIR/profiles/${profile}.env"

  if [[ -r "$profile_file" ]]; then
    FEATURES=""
    INSTALLS=""
    # shellcheck disable=SC1090
    source "$profile_file"
    selected_features="${FEATURES:-}"
    selected_installs="${INSTALLS:-}"
    FEATURES="$saved_features"
    INSTALLS="$saved_installs"

    if [[ -n "$selected_features" ]]; then
      for feature in $(split_csv "$selected_features"); do
        apply_feature "$feature" || return 1
      done
    fi
  else
    apply_profile "$profile" || return 1
  fi

  if [[ -n "$installs_var" ]]; then
    printf -v "$installs_var" '%s' "$selected_installs"
  fi
}

append_csv_unique() {
  local csv="$1"
  local item="$2"

  [[ -n "$item" ]] || {
    echo "$csv"
    return 0
  }

  case ",$csv," in
    *,"$item",*) echo "$csv" ;;
    ,,) echo "$item" ;;
    *) echo "${csv},${item}" ;;
  esac
}

merge_csv_lists() {
  local merged=""
  local list item

  for list in "$@"; do
    [[ -n "$list" ]] || continue
    for item in $(split_csv "$list"); do
      merged="$(append_csv_unique "$merged" "$item")"
    done
  done

  echo "$merged"
}

resolve_requested_state() {
  local cli_features="$FEATURES"
  local cli_installs="$INSTALLS"
  local profile_install_accum=""
  local profile profile_installs="" feature

  FEATURES=""
  INSTALLS=""

  if [[ -n "$PROFILES" ]]; then
    for profile in $(split_csv "$PROFILES"); do
      if ! is_valid_profile "$profile"; then
        echo "Invalid profile name: $profile" >&2
        exit 1
      fi

      apply_profile_selection "$profile" profile_installs || {
        echo "Unknown profile: $profile" >&2
        exit 1
      }
      profile_install_accum="$(merge_csv_lists "$profile_install_accum" "$profile_installs")"
    done
  fi

  FEATURES="$cli_features"
  INSTALLS="$(merge_csv_lists "$profile_install_accum" "$cli_installs")"

  if [[ -n "$FEATURES" ]]; then
    for feature in $(split_csv "$FEATURES"); do
      apply_feature "$feature" || {
        echo "Unknown feature: $feature" >&2
        exit 1
      }
    done
  fi
}

print_feature_list() {
  cat <<'FEATURES'
gnu_over_bsd
build_flags
auto_tools
ssh_agent
doppler_env
bash_it
git_signing
dev_tools
ops_tools
FEATURES
}

handle_list_commands() {
  local id desc_var desc

  if [[ "$LIST" -eq 1 ]]; then
    echo "Profiles: minimal, dev, ops"
    echo "Features:"
    print_feature_list | sed 's/^/  /'
    echo "Installers:"
    for id in $INSTALLERS; do
      echo "  $id"
    done
    exit 0
  fi

  if [[ "$LIST_PROFILES" -eq 1 ]]; then
    printf '%s\n' minimal dev ops
    exit 0
  fi

  if [[ "$LIST_FEATURES" -eq 1 ]]; then
    print_feature_list
    exit 0
  fi

  if [[ "$LIST_INSTALLERS" -eq 1 ]]; then
    for id in $INSTALLERS; do
      desc_var="INSTALL_DESC_${id}"
      desc="${!desc_var}"
      [[ -n "$desc" ]] || desc="$id"
      echo " - $id ($desc)"
    done
    exit 0
  fi
}

finalize_requested_state() {
  INSTALLS="$(merge_csv_lists "$INSTALLS" "$GROUP_INSTALLS")"
  export GET_BASHED_HOME="$PREFIX"
  export GET_BASHED_VIMRC_MODE="$VIMRC_MODE"
}

print_dry_run_summary() {
  echo "Dry run enabled. No changes will be made."
  echo "  Prefix: $PREFIX"
  echo "  Profiles: ${PROFILES:-<none>}"
  echo "  Features: gnu_over_bsd=${GET_BASHED_GNU} build_flags=${GET_BASHED_BUILD_FLAGS} auto_tools=${GET_BASHED_AUTO_TOOLS} ssh_agent=${GET_BASHED_SSH_AGENT} doppler_env=${GET_BASHED_USE_DOPPLER} bash_it=${GET_BASHED_USE_BASH_IT} git_signing=${GET_BASHED_GIT_SIGNING}"
  echo "  Installers: ${INSTALLS:-<none>}"
}
