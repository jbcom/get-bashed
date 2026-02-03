#!/usr/bin/env bash
# @file install
# @name get-bashed-installer
# @brief Installer and configurator for get-bashed.
# @description
#     Supports non-interactive and interactive installation with profiles,
#     feature flags, and installer bundles.

# shellcheck disable=SC3040
set -euo pipefail

if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo "Bash 4+ is required. Install a newer bash and re-run." >&2
  exit 1
fi

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
                  [--link-dotfiles]
                  [--name "Full Name"] [--email "me@example.com"]
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
source "$REPO_DIR/installers/tools.sh"
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
LINK_DOTFILES=0
USER_NAME=""
USER_EMAIL=""

# Feature flags (defaults)
GET_BASHED_GNU=0
GET_BASHED_BUILD_FLAGS=0
GET_BASHED_AUTO_TOOLS=0
GET_BASHED_SSH_AGENT=0
GET_BASHED_USE_DOPPLER=0
GET_BASHED_USE_BASH_IT=0
GET_BASHED_GIT_SIGNING=0

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
    --link-dotfiles)
      LINK_DOTFILES=1; shift ;;
    --name|-n)
      if [[ $# -lt 2 ]]; then
        echo "Error: --name requires a value" >&2
        usage
        exit 1
      fi
      USER_NAME="$2"; shift 2 ;;
    --email|-e)
      if [[ $# -lt 2 ]]; then
        echo "Error: --email requires a value" >&2
        usage
        exit 1
      fi
      USER_EMAIL="$2"; shift 2 ;;
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
    bash_it)
      GET_BASHED_USE_BASH_IT=$v
      if [[ "$v" -eq 1 ]]; then
        GROUP_INSTALLS="${GROUP_INSTALLS},bash_it"
      fi
      ;;
    git_signing) GET_BASHED_GIT_SIGNING=$v ;;
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
is_valid_profile() {
  case "$1" in
    minimal|dev|ops) return 0 ;;
    *) return 1 ;;
  esac
}

# @internal
apply_gitconfig() {
  local cfg="$PREFIX/gitconfig"
  [[ -r "$cfg" ]] || return 0

  if [[ -n "$USER_NAME" ]]; then
    git config -f "$cfg" user.name "$USER_NAME"
  fi
  if [[ -n "$USER_EMAIL" ]]; then
    git config -f "$cfg" user.email "$USER_EMAIL"
  fi
}

# @internal
ensure_block() {
  local file="$1" marker="$2" snippet="$3"
  mkdir -p "$(dirname "$file")"
  if [[ -r "$file" ]]; then
    if grep -Fq "$marker" "$file"; then
      return 0
    fi
  fi
  {
    echo ""
    echo "$marker"
    echo "$snippet"
  } >> "$file"
}

# @internal
backup_file() {
  local file="$1"
  [[ -e "$file" ]] || return 0
  local backup_dir="$PREFIX/backup"
  mkdir -p "$backup_dir"
  local base
  base="$(basename "$file")"
  local ts
  ts="$(date +%s)"
  mv "$file" "$backup_dir/${base}.${ts}"
}

# @internal
link_dotfile() {
  local name="$1"
  local src="$PREFIX/$name"
  local dest="$HOME/.${name}"
  if [[ ! -e "$src" ]]; then
    return 0
  fi
  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest" || true)"
    if [[ "$current" == "$src" ]]; then
      return 0
    fi
    backup_file "$dest"
  elif [[ -e "$dest" ]]; then
    backup_file "$dest"
  fi
  ln -s "$src" "$dest"
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

# Preserve CLI features/installers so profiles do not clobber them.
CLI_FEATURES="${FEATURES:-}"
CLI_INSTALLS="${INSTALLS:-}"
FEATURES=""
INSTALLS=""

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
      PROFILE_FEATURES="${FEATURES:-}"
      if [[ -n "$PROFILE_FEATURES" ]]; then
        for f in $(split_csv "$PROFILE_FEATURES"); do
          apply_feature "$f" || { echo "Unknown feature: $f"; exit 1; }
        done
      fi
      if [[ -n "${INSTALLS:-}" ]]; then
        GROUP_INSTALLS="${GROUP_INSTALLS},${INSTALLS}"
      fi
      FEATURES=""
      INSTALLS=""
    else
      apply_profile "$p" || { echo "Unknown profile: $p"; exit 1; }
    fi
  done
fi

FEATURES="$CLI_FEATURES"
INSTALLS="$CLI_INSTALLS"

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

      if [[ -z "$USER_NAME" ]]; then
        USER_NAME=$(dialog --clear --title "get-bashed" --inputbox "Git user.name" 8 60 "${USER_NAME}" 3>&1 1>&2 2>&3) || true
      fi
      if [[ -z "$USER_EMAIL" ]]; then
        USER_EMAIL=$(dialog --clear --title "get-bashed" --inputbox "Git user.email" 8 60 "${USER_EMAIL}" 3>&1 1>&2 2>&3) || true
      fi
    fi
  else
    if [[ "$YES" -eq 0 ]]; then
      prompt_yes_no "Proceed with installation?" || exit 1
    fi
    if prompt_yes_no "Enable GNU tools on macOS (gnu_over_bsd)?"; then GET_BASHED_GNU=1; fi
    if prompt_yes_no "Enable build flags (build_flags)?"; then GET_BASHED_BUILD_FLAGS=1; fi
    if prompt_yes_no "Enable auto tools (auto_tools)?"; then GET_BASHED_AUTO_TOOLS=1; fi
    if prompt_yes_no "Enable ssh-agent (ssh_agent)?"; then GET_BASHED_SSH_AGENT=1; fi
    if prompt_yes_no "Enable doppler env (doppler_env)?"; then GET_BASHED_USE_DOPPLER=1; fi
    if prompt_yes_no "Enable bash-it (bash_it)?"; then GET_BASHED_USE_BASH_IT=1; fi
    if prompt_yes_no "Enable git signing (git_signing)?"; then GET_BASHED_GIT_SIGNING=1; fi
  fi
fi

if [[ "$LIST" -eq 1 ]]; then
  echo "Profiles: minimal, dev, ops"
  echo "Features:"
  echo "  gnu_over_bsd"
  echo "  build_flags"
  echo "  auto_tools"
  echo "  ssh_agent"
  echo "  doppler_env"
  echo "  bash_it"
  echo "  git_signing"
  echo "  dev_tools"
  echo "  ops_tools"
  echo "Installers:"
  for id in $INSTALLERS; do
    echo "  $id"
  done
  exit 0
fi

if [[ "$LIST_PROFILES" -eq 1 ]]; then
  echo "minimal"
  echo "dev"
  echo "ops"
  exit 0
fi

if [[ "$LIST_FEATURES" -eq 1 ]]; then
  echo "gnu_over_bsd"
  echo "build_flags"
  echo "auto_tools"
  echo "ssh_agent"
  echo "doppler_env"
  echo "bash_it"
  echo "git_signing"
  echo "dev_tools"
  echo "ops_tools"
  exit 0
fi

if [[ "$LIST_INSTALLERS" -eq 1 ]]; then
  for id in $INSTALLERS; do
    desc_var="INSTALL_DESC_${id}"
    desc="${!desc_var}"
    [[ -z "$desc" ]] && desc="$id"
    echo " - $id ($desc)"
  done
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run enabled. No changes will be made."
  echo "  Prefix: $PREFIX"
  echo "  Profiles: ${PROFILES:-<none>}"
  echo "  Features: gnu_over_bsd=${GET_BASHED_GNU} build_flags=${GET_BASHED_BUILD_FLAGS} auto_tools=${GET_BASHED_AUTO_TOOLS} ssh_agent=${GET_BASHED_SSH_AGENT} doppler_env=${GET_BASHED_USE_DOPPLER} bash_it=${GET_BASHED_USE_BASH_IT} git_signing=${GET_BASHED_GIT_SIGNING}"
  echo "  Installers: ${INSTALLS:-<none>}"
fi

mkdir -p "$PREFIX"
export GET_BASHED_HOME="$PREFIX"

copy_tree() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  if [[ "${FORCE:-0}" -eq 1 ]]; then
    rsync -a --delete "$src"/ "$dest"/
  else
    rsync -a "$src"/ "$dest"/
  fi
}

# Copy base assets
copy_tree "$REPO_DIR/bashrc.d" "$PREFIX/bashrc.d"
cp -f "$REPO_DIR/bashrc" "$PREFIX/bashrc"
cp -f "$REPO_DIR/bash_profile" "$PREFIX/bash_profile"
cp -f "$REPO_DIR/bash_aliases" "$PREFIX/bash_aliases"
cp -f "$REPO_DIR/inputrc" "$PREFIX/inputrc"
cp -f "$REPO_DIR/vimrc" "$PREFIX/vimrc"
cp -f "$REPO_DIR/gitconfig" "$PREFIX/gitconfig"

# secrets.d bootstrap (only inside GET_BASHED_HOME)
mkdir -p "$PREFIX/secrets.d"
if [[ ! -e "$PREFIX/secrets.d/00-local.sh" ]]; then
  cat <<'__SECRETS__' > "$PREFIX/secrets.d/00-local.sh"
# Place local secrets here. Example:
# export FOO="bar"
__SECRETS__
fi

# Write config file
{
  echo "# Generated by get-bashed installer"
  echo "export GET_BASHED_GNU=${GET_BASHED_GNU}"
  echo "export GET_BASHED_BUILD_FLAGS=${GET_BASHED_BUILD_FLAGS}"
  echo "export GET_BASHED_AUTO_TOOLS=${GET_BASHED_AUTO_TOOLS}"
  echo "export GET_BASHED_SSH_AGENT=${GET_BASHED_SSH_AGENT}"
  echo "export GET_BASHED_USE_DOPPLER=${GET_BASHED_USE_DOPPLER}"
  echo "export GET_BASHED_USE_BASH_IT=${GET_BASHED_USE_BASH_IT}"
  echo "export GET_BASHED_GIT_SIGNING=${GET_BASHED_GIT_SIGNING}"
  if [[ -n "$USER_NAME" ]]; then
    echo "export GET_BASHED_USER_NAME=\"${USER_NAME}\""
  fi
  if [[ -n "$USER_EMAIL" ]]; then
    echo "export GET_BASHED_USER_EMAIL=\"${USER_EMAIL}\""
  fi
} > "$PREFIX/get-bashedrc.sh"

apply_gitconfig

# Link dotfiles if requested (into $HOME only)
if [[ "$LINK_DOTFILES" -eq 1 ]]; then
  link_dotfile "bashrc"
  link_dotfile "bash_profile"
  link_dotfile "inputrc"
  link_dotfile "bash_aliases"
  link_dotfile "vimrc"
  if [[ -n "$USER_NAME" && -n "$USER_EMAIL" ]]; then
    link_dotfile "gitconfig"
  else
    echo "Skipping gitconfig link (missing --name/--email)." >&2
  fi
else
  # Update login shell snippets (idempotent)
  BASHRC_LINE="# get-bashed: source modular bashrc"
  BASHRC_SNIP='if [[ -r "$HOME/.get-bashed/bashrc" ]]; then source "$HOME/.get-bashed/bashrc"; fi'
  BASH_PROFILE_LINE="# get-bashed: source login bash_profile"
  BASH_PROFILE_SNIP='if [[ -r "$HOME/.get-bashed/bash_profile" ]]; then source "$HOME/.get-bashed/bash_profile"; fi'

  ensure_block "$HOME/.bashrc" "$BASHRC_LINE" "$BASHRC_SNIP"
  ensure_block "$HOME/.bash_profile" "$BASH_PROFILE_LINE" "$BASH_PROFILE_SNIP"
fi

# Installers
if [[ -n "$INSTALLS" ]]; then
  INSTALLS="${INSTALLS},${GROUP_INSTALLS#,}"
else
  INSTALLS="${GROUP_INSTALLS#,}"
fi

declare -A INSTALL_IN_PROGRESS=()
declare -A INSTALL_DONE=()

get_deps() {
  local id="$1"
  echo "${TOOL_DEPS[$id]:-}"
}

is_done() {
  local id="$1"
  [[ "${INSTALL_DONE[$id]:-}" == "1" ]]
}

mark_done() {
  local id="$1"
  INSTALL_DONE["$id"]=1
}

run_install() {
  local id="$1"
  if is_done "$id"; then
    return 0
  fi
  if [[ "${INSTALL_IN_PROGRESS[$id]:-}" == "1" ]]; then
    echo "Circular dependency detected while installing $id" >&2
    return 1
  fi
  INSTALL_IN_PROGRESS["$id"]=1
  local deps
  deps="$(get_deps "$id")"
  if [[ -n "$deps" ]]; then
    for dep in $(split_csv "$deps"); do
      run_install "$dep" || return 1
    done
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would install: $id"
  else
    if declare -f "install_${id}" >/dev/null 2>&1; then
      "install_${id}"
    else
      install_tool "$id"
    fi
  fi
  unset "INSTALL_IN_PROGRESS[$id]"
  mark_done "$id"
}

if [[ -n "$INSTALLS" ]]; then
  for id in $(split_csv "$INSTALLS"); do
    run_install "$id"
  done
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  exit 0
fi

echo "get-bashed installed to $PREFIX"
