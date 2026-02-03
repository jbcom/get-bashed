#!/bin/sh
# POSIX shell bootstrap that re-execs with bash for full functionality.
if [ -z "${GET_BASHED_BOOTSTRAPPED:-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    GET_BASHED_BOOTSTRAPPED=1 exec bash "$0" "$@"
  fi
  echo "Bash is required to run this installer." >&2
  echo "Install bash (recommended latest) and re-run: sh install.sh" >&2
  exit 1
fi

# shellcheck shell=bash
# @file install
# @name get-bashed-installer
# @brief Installer and configurator for get-bashed.
# @description
#     Supports non-interactive and interactive installation with profiles,
#     feature flags, and installer bundles.

set -euo pipefail

# @description Print usage help.
# @noargs
usage() {
  cat <<'USAGE'
Usage: install.sh [--prefix PATH] [--force] [--with-ui]
                  [--auto] [--yes]
                  [--profiles minimal|dev|ops[,..]]
                  [--features gnu_over_bsd,build_flags,...]
                  [--install brew,asdf,doppler,...]
                  [--vimrc-mode awesome|basic]
                  [--list] [--list-profiles] [--list-features] [--list-installers]
                  [--dry-run]

Notes:
- --auto disables prompts.
- --yes auto-accepts prompts.
- profiles set defaults; features override defaults.
USAGE
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPO_DIR/installers/_helpers.sh"
PREFIX="${GET_BASHED_HOME:-$HOME/.get-bashed}"
FORCE=0
WITH_UI=0
AUTO=0
YES=0
PROFILES=""
FEATURES=""
INSTALLS=""
LIST=0
DRY_RUN=0
LIST_PROFILES=0
LIST_FEATURES=0
LIST_INSTALLERS=0
GROUP_INSTALLS=""
VIMRC_MODE="awesome"

# Feature flags (defaults)
GET_BASHED_GNU=0
GET_BASHED_BUILD_FLAGS=0
GET_BASHED_AUTO_TOOLS=0
GET_BASHED_SSH_AGENT=0
GET_BASHED_USE_DOPPLER=0
GET_BASHED_USE_BASH_IT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)
      if [[ $# -lt 2 ]]; then
        echo "Error: --prefix requires a value" >&2
        usage
        exit 1
      fi
      PREFIX="$2"; shift 2 ;;
    --force)
      FORCE=1; shift ;;
    --with-ui)
      WITH_UI=1; shift ;;
    --auto|-a)
      AUTO=1; shift ;;
    --yes|-y)
      YES=1; shift ;;
    --profiles|-w)
      if [[ $# -lt 2 ]]; then
        echo "Error: --profiles requires a value" >&2
        usage
        exit 1
      fi
      PROFILES="$2"; shift 2 ;;
    --features)
      if [[ $# -lt 2 ]]; then
        echo "Error: --features requires a value" >&2
        usage
        exit 1
      fi
      FEATURES="$2"; shift 2 ;;
    --install|-i)
      if [[ $# -lt 2 ]]; then
        echo "Error: --install requires a value" >&2
        usage
        exit 1
      fi
      INSTALLS="$2"; shift 2 ;;
    --vimrc-mode)
      if [[ $# -lt 2 ]]; then
        echo "Error: --vimrc-mode requires a value" >&2
        usage
        exit 1
      fi
      VIMRC_MODE="$2"; shift 2 ;;
    --list)
      LIST=1; shift ;;
    --list-profiles)
      LIST_PROFILES=1; shift ;;
    --list-features)
      LIST_FEATURES=1; shift ;;
    --list-installers)
      LIST_INSTALLERS=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [[ "$YES" -eq 1 || "$AUTO" -eq 1 ]]; then
  export GET_BASHED_AUTO_APPROVE=1
fi

# @description Apply a built-in profile.
# @arg $1 string Profile name.
# @exitcode 0 If applied.
# @exitcode 1 If unknown.
apply_profile() {
  local p="$1"
  case "$p" in
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
  local f="$1" v=1
  if [[ "$f" == no-* ]]; then
    v=0
    f="${f#no-}"
  fi
  case "$f" in
    gnu_over_bsd) GET_BASHED_GNU=$v ;;
    build_flags) GET_BASHED_BUILD_FLAGS=$v ;;
    auto_tools) GET_BASHED_AUTO_TOOLS=$v ;;
    ssh_agent) GET_BASHED_SSH_AGENT=$v ;;
    doppler_env) GET_BASHED_USE_DOPPLER=$v ;;
    bash_it) GET_BASHED_USE_BASH_IT=$v ;;
    dev_tools) GROUP_INSTALLS="${GROUP_INSTALLS},rg,fd,bat,fzf,jq,yq,tree,direnv,starship,nodejs,python,bash" ;;
    ops_tools) GROUP_INSTALLS="${GROUP_INSTALLS},gh,git_lfs,terraform,awscli,kubectl,helm,stern,doppler,nodejs,python,java,bash" ;;
    *) return 1 ;;
  esac
}

# @description Split a comma-delimited list into space-delimited output.
# @arg $1 string Comma list.
# @stdout Space-delimited items.
split_csv() {
  local s="$1"; IFS=',' read -r -a _parts <<<"$s"; echo "${_parts[@]}";
}

# @internal
is_valid_id() {
  [[ "$1" =~ ^[a-z0-9_]+$ ]]
}

# @internal
is_valid_profile() {
  [[ "$1" =~ ^[a-z0-9_-]+$ ]]
}

# @internal
installer_exists() {
  local needle="$1" id
  for id in $INSTALLERS; do
    [[ "$id" == "$needle" ]] && return 0
  done
  return 1
}

# Installer registry
INSTALLERS=""
# @internal
load_installers() {
  local f
  # shellcheck disable=SC1090
  source "$REPO_DIR/installers/_helpers.sh"
  for f in "$REPO_DIR/installers"/*.sh; do
    [[ "$f" == "$REPO_DIR/installers/_helpers.sh" ]] && continue
    # shellcheck disable=SC1090
    source "$f"
    if ! is_valid_id "$INSTALL_ID"; then
      echo "Invalid installer id: $INSTALL_ID (from $f)" >&2
      exit 1
    fi
    INSTALLERS="$INSTALLERS $INSTALL_ID"
    printf -v "INSTALL_DEPS_${INSTALL_ID}" "%s" "${INSTALL_DEPS}"
    printf -v "INSTALL_DESC_${INSTALL_ID}" "%s" "${INSTALL_DESC:-}"
    printf -v "INSTALL_PLATFORMS_${INSTALL_ID}" "%s" "${INSTALL_PLATFORMS:-}"
  done
}

# @internal
get_deps() {
  local id="$1"
  local var="INSTALL_DEPS_${id}"
  echo "${!var:-}"
}

# @internal
is_done() {
  local id="$1"
  local var="INSTALLED_${id}"
  [[ "${!var:-0}" == 1 ]]
}

# @internal
mark_done() {
  local id="$1"
  printf -v "INSTALLED_${id}" "%s" 1
}

# @internal
run_install() {
  local id="$1" dep
  if ! is_valid_id "$id"; then
    echo "Invalid installer id: $id" >&2
    return 1
  fi
  if is_done "$id"; then
    return 0
  fi
  for dep in $(get_deps "$id"); do
    run_install "$dep"
  done
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would install: $id"
  else
    if declare -f "install_${id}" >/dev/null 2>&1; then
      "install_${id}"
    else
      echo "Installer not found: $id" >&2
      return 1
    fi
  fi
  mark_done "$id"
}

# @internal
install_dialog() {
  if command -v dialog >/dev/null 2>&1; then
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    brew install dialog
  elif command -v apt-get >/dev/null 2>&1; then
    apt_install dialog
  elif command -v dnf >/dev/null 2>&1; then
    dnf_install dialog
  elif command -v yum >/dev/null 2>&1; then
    yum_install dialog
  fi
}

# @internal
prompt_yes_no() {
  local label="$1" answer
  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi
  read -r -p "$label [y/N]: " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

if [[ "$WITH_UI" -eq 1 ]] && [[ "$AUTO" -eq 0 ]]; then
  install_dialog || true
fi

# If stdin isn't a TTY, default to non-interactive.
if [[ ! -t 0 ]] && [[ "$AUTO" -eq 0 ]]; then
  AUTO=1
fi

# Load installer registry early for interactive UI.
load_installers

# Apply profiles first
if [[ -n "$PROFILES" ]]; then
  for p in $(split_csv "$PROFILES"); do
    if ! is_valid_profile "$p"; then
      echo "Invalid profile name: $p" >&2
      exit 1
    fi
    # Load profile file if present
    PROFILE_FILE="$REPO_DIR/profiles/${p}.env"
    if [[ -r "$PROFILE_FILE" ]]; then
      # shellcheck disable=SC1090
      source "$PROFILE_FILE"
      if [[ -n "${FEATURES:-}" ]]; then
        for f in $(split_csv "$FEATURES"); do
          apply_feature "$f" || { echo "Unknown feature: $f"; exit 1; }
        done
      fi
      if [[ -n "${INSTALLS:-}" ]]; then
        GROUP_INSTALLS="${GROUP_INSTALLS},${INSTALLS}"
      fi
    else
      apply_profile "$p" || { echo "Unknown profile: $p"; exit 1; }
    fi
  done
fi

# Apply features overrides
if [[ -n "$FEATURES" ]]; then
  for f in $(split_csv "$FEATURES"); do
    apply_feature "$f" || { echo "Unknown feature: $f"; exit 1; }
  done
fi

# Interactive selection
if [[ "$AUTO" -eq 0 ]]; then
  if [[ "$WITH_UI" -eq 1 ]] && command -v dialog >/dev/null 2>&1; then
    if [[ "$YES" -ne 1 ]]; then
      PROFILE_CHOICE=$(dialog --clear --title "get-bashed" --menu "Select a profile" 12 60 3 \
        minimal "Minimal defaults" \
        dev "Developer workstation" \
        ops "Ops/Platform workstation" \
        3>&1 1>&2 2>&3) || true
      if [[ -n "$PROFILE_CHOICE" ]]; then
        apply_profile "$PROFILE_CHOICE"
      fi

      CHOICES=$(dialog --clear --title "get-bashed" --checklist "Enable features" 18 70 8 \
        gnu_over_bsd "Prefer GNU tools on macOS" "$( [[ "$GET_BASHED_GNU" -eq 1 ]] && echo on || echo off )" \
        build_flags "Enable runtime build flags" "$( [[ "$GET_BASHED_BUILD_FLAGS" -eq 1 ]] && echo on || echo off )" \
        auto_tools "Auto-install optional tools" "$( [[ "$GET_BASHED_AUTO_TOOLS" -eq 1 ]] && echo on || echo off )" \
        ssh_agent "Auto-start ssh-agent" "$( [[ "$GET_BASHED_SSH_AGENT" -eq 1 ]] && echo on || echo off )" \
        doppler_env "Enable Doppler env usage" "$( [[ "$GET_BASHED_USE_DOPPLER" -eq 1 ]] && echo on || echo off )" \
        bash_it "Enable bash-it (if installed)" "$( [[ "$GET_BASHED_USE_BASH_IT" -eq 1 ]] && echo on || echo off )" \
        dev_tools "Developer tool bundle" off \
        ops_tools "Ops tool bundle" off \
        3>&1 1>&2 2>&3) || true

      GET_BASHED_GNU=0
      GET_BASHED_BUILD_FLAGS=0
      GET_BASHED_AUTO_TOOLS=0
      GET_BASHED_SSH_AGENT=0
      GET_BASHED_USE_DOPPLER=0
      GET_BASHED_USE_BASH_IT=0

      for choice in $CHOICES; do
        apply_feature "${choice//\"/}" || true
      done

      dialog_opts=()
      for id in $INSTALLERS; do
        desc_var="INSTALL_DESC_${id}"
        desc="${!desc_var}"
        [[ -z "$desc" ]] && desc="$id"
        default_state="off"
        if [[ "$id" == "dialog" ]]; then
          default_state="on"
        fi
        dialog_opts+=("$id" "$desc" "$default_state")
      done

      INSTALLS_DIALOG=$(dialog --clear --title "get-bashed" --checklist "Select installers" 20 80 12 \
        "${dialog_opts[@]}" \
        3>&1 1>&2 2>&3) || true
      if [[ -n "$INSTALLS_DIALOG" ]]; then
        INSTALLS="${INSTALLS_DIALOG//\"/}"
        INSTALLS="${INSTALLS// /,}"
      fi

      dialog --clear --title "get-bashed" --yesno \
        "Proceed with installation?\n\nFeatures: gnu_over_bsd=${GET_BASHED_GNU} build_flags=${GET_BASHED_BUILD_FLAGS} auto_tools=${GET_BASHED_AUTO_TOOLS} ssh_agent=${GET_BASHED_SSH_AGENT} doppler_env=${GET_BASHED_USE_DOPPLER} bash_it=${GET_BASHED_USE_BASH_IT}\nInstallers: ${INSTALLS}" \
        12 70 || exit 0
    fi
  else
    if [[ "$YES" -ne 1 ]]; then
      echo "Configure installation options (interactive)"
      read -r -p "Profile (minimal/dev/ops, enter to skip): " PROFILE_CHOICE
      if [[ -n "$PROFILE_CHOICE" ]]; then
        apply_profile "$PROFILE_CHOICE" || true
      fi

      prompt_yes_no "Enable GNU tools on macOS (gnu_over_bsd)?" && GET_BASHED_GNU=1
      prompt_yes_no "Enable build flags (build_flags)?" && GET_BASHED_BUILD_FLAGS=1
      prompt_yes_no "Auto-install optional tools (auto_tools)?" && GET_BASHED_AUTO_TOOLS=1
      prompt_yes_no "Start ssh-agent automatically (ssh_agent)?" && GET_BASHED_SSH_AGENT=1
      prompt_yes_no "Enable Doppler env support (doppler_env)?" && GET_BASHED_USE_DOPPLER=1
      prompt_yes_no "Enable bash-it (bash_it)?" && GET_BASHED_USE_BASH_IT=1
      prompt_yes_no "Include developer tool bundle (dev_tools)?" && apply_feature "dev_tools"
      prompt_yes_no "Include ops tool bundle (ops_tools)?" && apply_feature "ops_tools"

      read -r -p "Installers (comma list, e.g. brew,asdf,doppler): " INSTALLS_INPUT
      if [[ -n "$INSTALLS_INPUT" ]]; then
        INSTALLS="$INSTALLS_INPUT"
      fi

      echo "Proceeding with:"
      echo "  Features: gnu_over_bsd=${GET_BASHED_GNU} build_flags=${GET_BASHED_BUILD_FLAGS} auto_tools=${GET_BASHED_AUTO_TOOLS} ssh_agent=${GET_BASHED_SSH_AGENT} doppler_env=${GET_BASHED_USE_DOPPLER} bash_it=${GET_BASHED_USE_BASH_IT}"
      echo "  Installers: ${INSTALLS}"
      prompt_yes_no "Continue?" || exit 0
    fi
  fi
fi

# Merge group installs into INSTALLS
if [[ -n "${GROUP_INSTALLS:-}" ]]; then
  if [[ -n "$INSTALLS" ]]; then
    INSTALLS="${INSTALLS},${GROUP_INSTALLS}"
  else
    INSTALLS="${GROUP_INSTALLS}"
  fi
fi

# Validate vimrc mode
case "$VIMRC_MODE" in
  awesome|basic) ;;
  *)
    echo "Invalid --vimrc-mode: $VIMRC_MODE (expected awesome|basic)" >&2
    exit 1
    ;;
esac

# Deduplicate installers
if [[ -n "$INSTALLS" ]]; then
  INSTALLS="$(echo "$INSTALLS" | tr ',' '\n' | awk 'NF && !seen[$0]++' | paste -sd, -)"
fi

# Validate installer ids (after dedupe)
if [[ -n "$INSTALLS" ]]; then
  for id in $(split_csv "$INSTALLS"); do
    if ! installer_exists "$id"; then
      echo "Unknown installer: $id" >&2
      exit 1
    fi
  done
fi

if [[ "$LIST_FEATURES" -eq 1 ]]; then
  echo "Features:"
  echo "  gnu_over_bsd"
  echo "  build_flags"
  echo "  auto_tools"
  echo "  ssh_agent"
  echo "  doppler_env"
  echo "  bash_it"
  echo "  dev_tools (bundle)"
  echo "  ops_tools (bundle)"
  exit 0
fi

if [[ "$LIST_PROFILES" -eq 1 ]]; then
  echo "Profiles:"
  for p in "$REPO_DIR"/profiles/*.env; do
    [[ -e "$p" ]] || continue
    echo "  - $(basename "$p" .env)"
  done
  exit 0
fi

if [[ "$LIST_INSTALLERS" -eq 1 || "$LIST" -eq 1 ]]; then
  echo "Available installers:"
  for id in $INSTALLERS; do
    desc_var="INSTALL_DESC_${id}"
    plat_var="INSTALL_PLATFORMS_${id}"
    desc="${!desc_var}"
    plats="${!plat_var}"
    printf "  - %s%s%s\n" "$id" \
      "$( [[ -n "$desc" ]] && printf " :: %s" "$desc" )" \
      "$( [[ -n "$plats" ]] && printf " [%s]" "$plats" )"
  done
  exit 0
fi

if [[ -n "$INSTALLS" ]]; then
  export GET_BASHED_HOME="$PREFIX"
  export GET_BASHED_VIMRC_MODE="$VIMRC_MODE"
  for id in $(split_csv "$INSTALLS"); do
    run_install "$id"
  done
fi

# Install files
if [[ -e "$PREFIX" && "$FORCE" -ne 1 ]]; then
  BACKUP="${PREFIX}.bak.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing $PREFIX to $BACKUP"
  mv "$PREFIX" "$BACKUP"
fi

mkdir -p "$PREFIX"

rsync -a \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'tests' \
  --exclude 'docs' \
  "$REPO_DIR/" "$PREFIX/"

chmod +x "$PREFIX/bin"/* 2>/dev/null || true

# secrets.d bootstrap
mkdir -p "$PREFIX/secrets.d"
if [[ ! -e "$PREFIX/secrets.d/00-local.sh" ]]; then
  cat <<'__SECRETS__' > "$PREFIX/secrets.d/00-local.sh"
# Local secrets for get-bashed.
# This file is intentionally untracked.
__SECRETS__
fi

CONFIG_FILE="$PREFIX/get-bashedrc.sh"
cat <<__CFG__ > "$CONFIG_FILE"
# Generated by get-bashed installer. Edit if needed.
export GET_BASHED_GNU=${GET_BASHED_GNU}
export GET_BASHED_BUILD_FLAGS=${GET_BASHED_BUILD_FLAGS}
export GET_BASHED_AUTO_TOOLS=${GET_BASHED_AUTO_TOOLS}
export GET_BASHED_SSH_AGENT=${GET_BASHED_SSH_AGENT}
export GET_BASHED_USE_DOPPLER=${GET_BASHED_USE_DOPPLER}
export GET_BASHED_USE_BASH_IT=${GET_BASHED_USE_BASH_IT}
export GET_BASHED_VIMRC_MODE=${VIMRC_MODE}
__CFG__

# @internal
ensure_block() {
  local file="$1" marker="$2" content="$3"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if ! grep -Fqs "$marker" "$file"; then
    printf '\n%s\n%s\n' "$marker" "$content" >> "$file"
  fi
}

BASHRC_LINE="# get-bashed: source modular bashrc"
BASHRC_SNIP='if [[ -r "$HOME/.get-bashed/bashrc" ]]; then source "$HOME/.get-bashed/bashrc"; fi'

BASH_PROFILE_LINE="# get-bashed: source login bash_profile"
BASH_PROFILE_SNIP='if [[ -r "$HOME/.get-bashed/bash_profile" ]]; then source "$HOME/.get-bashed/bash_profile"; fi'

ensure_block "$HOME/.bashrc" "$BASHRC_LINE" "$BASHRC_SNIP"
ensure_block "$HOME/.bash_profile" "$BASH_PROFILE_LINE" "$BASH_PROFILE_SNIP"

echo "Installed get-bashed to $PREFIX"
