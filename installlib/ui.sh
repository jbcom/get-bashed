#!/usr/bin/env bash

# shellcheck disable=SC2153

install_dialog() {
  if command -v dialog >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew_exec install dialog
  elif command -v apt-get >/dev/null 2>&1; then
    apt_install dialog
  elif command -v dnf >/dev/null 2>&1; then
    dnf_install dialog
  elif command -v yum >/dev/null 2>&1; then
    yum_install dialog
  fi
}

prompt_yes_no() {
  local label="$1"
  local default="${2:-0}"
  local answer
  local prompt='[y/N]'

  if [[ "$YES" -eq 1 ]]; then
    [[ "$default" -eq 1 ]]
    return
  fi

  if [[ "$default" -eq 1 ]]; then
    prompt='[Y/n]'
  fi

  read -r -p "$label $prompt: " answer
  if [[ -z "$answer" ]]; then
    [[ "$default" -eq 1 ]]
    return
  fi

  [[ "$answer" =~ ^[Yy]$ ]]
}

run_interactive_selection() {
  if [[ "$AUTO" -eq 1 ]]; then
    return 0
  fi

  if [[ "$WITH_UI" -eq 1 ]] && command -v dialog >/dev/null 2>&1; then
    run_dialog_selection
    return 0
  fi

  run_prompt_selection
}

run_dialog_selection() {
  local profile_choice choices installs_dialog
  local profile_installs="" current_installs=""
  local id desc_var desc default_state
  local action_opts=()

  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi

  profile_choice=$(dialog --clear --title "get-bashed" --menu "Select a profile" 12 60 3 \
    minimal "Minimal defaults" \
    dev "Developer workstation" \
    ops "Ops/Platform workstation" \
    3>&1 1>&2 2>&3) || true
  if [[ -n "$profile_choice" ]]; then
    apply_profile_selection "$profile_choice" profile_installs || true
    INSTALLS="$(merge_csv_lists "$INSTALLS" "$profile_installs")"
  fi

  choices=$(dialog --clear --title "get-bashed" --checklist "Enable features" 18 70 8 \
    gnu_over_bsd "Prefer GNU tools on macOS" "$( [[ "$GET_BASHED_GNU" -eq 1 ]] && echo on || echo off )" \
    build_flags "Enable runtime build flags" "$( [[ "$GET_BASHED_BUILD_FLAGS" -eq 1 ]] && echo on || echo off )" \
    auto_tools "Auto-install optional tools" "$( [[ "$GET_BASHED_AUTO_TOOLS" -eq 1 ]] && echo on || echo off )" \
    ssh_agent "Auto-start ssh-agent" "$( [[ "$GET_BASHED_SSH_AGENT" -eq 1 ]] && echo on || echo off )" \
    doppler_env "Enable Doppler integration" "$( [[ "$GET_BASHED_USE_DOPPLER" -eq 1 ]] && echo on || echo off )" \
    bash_it "Enable bash-it (if installed)" "$( [[ "$GET_BASHED_USE_BASH_IT" -eq 1 ]] && echo on || echo off )" \
    git_signing "Enable git signing (gnupg)" "$( [[ "$GET_BASHED_GIT_SIGNING" -eq 1 ]] && echo on || echo off )" \
    dev_tools "Developer tool bundle" off \
    ops_tools "Ops tool bundle" off \
    3>&1 1>&2 2>&3) || true

  GET_BASHED_GNU=0
  GET_BASHED_BUILD_FLAGS=0
  GET_BASHED_AUTO_TOOLS=0
  GET_BASHED_SSH_AGENT=0
  GET_BASHED_USE_DOPPLER=0
  GET_BASHED_USE_BASH_IT=0
  GET_BASHED_GIT_SIGNING=0
  GROUP_INSTALLS=""

  local choice
  for choice in $choices; do
    apply_feature "${choice//\"/}" || true
  done

  current_installs="$(merge_csv_lists "$INSTALLS" "$GROUP_INSTALLS")"
  for id in $INSTALLERS; do
    desc_var="INSTALL_DESC_${id}"
    desc="${!desc_var}"
    [[ -n "$desc" ]] || desc="$id"
    default_state="off"
    case ",$current_installs," in
      *,"$id",*) default_state="on" ;;
      *) [[ "$id" == "dialog" ]] && default_state="on" ;;
    esac
    action_opts+=("$id" "$desc" "$default_state")
  done

  installs_dialog=$(dialog --clear --title "get-bashed" --checklist "Select installers" 20 80 12 \
    "${action_opts[@]}" \
    3>&1 1>&2 2>&3) || true
  if [[ -n "$installs_dialog" ]]; then
    INSTALLS="${installs_dialog//\"/}"
    INSTALLS="${INSTALLS// /,}"
  fi

  if [[ -z "$USER_NAME" ]]; then
    USER_NAME=$(dialog --clear --title "get-bashed" --inputbox "Git user.name" 8 60 "$USER_NAME" 3>&1 1>&2 2>&3) || true
  fi
  if [[ -z "$USER_EMAIL" ]]; then
    USER_EMAIL=$(dialog --clear --title "get-bashed" --inputbox "Git user.email" 8 60 "$USER_EMAIL" 3>&1 1>&2 2>&3) || true
  fi
}

run_prompt_selection() {
  local default_gnu="$GET_BASHED_GNU"
  local default_build_flags="$GET_BASHED_BUILD_FLAGS"
  local default_auto_tools="$GET_BASHED_AUTO_TOOLS"
  local default_ssh_agent="$GET_BASHED_SSH_AGENT"
  local default_doppler="$GET_BASHED_USE_DOPPLER"
  local default_bash_it="$GET_BASHED_USE_BASH_IT"
  local default_git_signing="$GET_BASHED_GIT_SIGNING"

  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi

  if [[ "$YES" -eq 0 ]]; then
    prompt_yes_no "Proceed with installation?" || exit 1
  fi

  GET_BASHED_GNU=0
  GET_BASHED_BUILD_FLAGS=0
  GET_BASHED_AUTO_TOOLS=0
  GET_BASHED_SSH_AGENT=0
  GET_BASHED_USE_DOPPLER=0
  GET_BASHED_USE_BASH_IT=0
  GET_BASHED_GIT_SIGNING=0
  GROUP_INSTALLS=""

  if prompt_yes_no "Enable GNU tools on macOS (gnu_over_bsd)?" "$default_gnu"; then apply_feature gnu_over_bsd; fi
  if prompt_yes_no "Enable build flags (build_flags)?" "$default_build_flags"; then apply_feature build_flags; fi
  if prompt_yes_no "Enable auto tools (auto_tools)?" "$default_auto_tools"; then apply_feature auto_tools; fi
  if prompt_yes_no "Enable ssh-agent (ssh_agent)?" "$default_ssh_agent"; then apply_feature ssh_agent; fi
  if prompt_yes_no "Enable Doppler integration (doppler_env)?" "$default_doppler"; then apply_feature doppler_env; fi
  if prompt_yes_no "Enable bash-it (bash_it)?" "$default_bash_it"; then apply_feature bash_it; fi
  if prompt_yes_no "Enable git signing (git_signing)?" "$default_git_signing"; then apply_feature git_signing; fi
}
