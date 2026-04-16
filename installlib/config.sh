#!/usr/bin/env bash

# shellcheck disable=SC2034

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

init_install_state() {
  PREFIX="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  FORCE=0
  WITH_UI=0
  AUTO=0
  YES=0
  PROFILES=""
  FEATURES=""
  INSTALLS=""
  GROUP_INSTALLS=""
  LIST=0
  DRY_RUN=0
  LIST_PROFILES=0
  LIST_FEATURES=0
  LIST_INSTALLERS=0
  VIMRC_MODE="awesome"
  LINK_DOTFILES=0
  USER_NAME=""
  USER_EMAIL=""

  GET_BASHED_GNU=0
  GET_BASHED_BUILD_FLAGS=0
  GET_BASHED_AUTO_TOOLS=0
  GET_BASHED_SSH_AGENT=0
  GET_BASHED_USE_DOPPLER=0
  GET_BASHED_USE_BASH_IT=0
  GET_BASHED_GIT_SIGNING=0
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prefix)
        [[ $# -ge 2 ]] || {
          echo "Error: --prefix requires a value" >&2
          usage
          exit 1
        }
        PREFIX="$2"
        shift 2
        ;;
      --force)
        FORCE=1
        shift
        ;;
      --with-ui)
        WITH_UI=1
        shift
        ;;
      --auto|-a)
        AUTO=1
        shift
        ;;
      --yes|-y)
        YES=1
        shift
        ;;
      --profiles|-w)
        [[ $# -ge 2 ]] || {
          echo "Error: --profiles requires a value" >&2
          usage
          exit 1
        }
        PROFILES="$2"
        shift 2
        ;;
      --features)
        [[ $# -ge 2 ]] || {
          echo "Error: --features requires a value" >&2
          usage
          exit 1
        }
        FEATURES="$2"
        shift 2
        ;;
      --install|-i)
        [[ $# -ge 2 ]] || {
          echo "Error: --install requires a value" >&2
          usage
          exit 1
        }
        INSTALLS="$2"
        shift 2
        ;;
      --vimrc-mode)
        [[ $# -ge 2 ]] || {
          echo "Error: --vimrc-mode requires a value" >&2
          usage
          exit 1
        }
        VIMRC_MODE="$2"
        shift 2
        ;;
      --link-dotfiles)
        LINK_DOTFILES=1
        shift
        ;;
      --name|-n)
        [[ $# -ge 2 ]] || {
          echo "Error: --name requires a value" >&2
          usage
          exit 1
        }
        USER_NAME="$2"
        shift 2
        ;;
      --email|-e)
        [[ $# -ge 2 ]] || {
          echo "Error: --email requires a value" >&2
          usage
          exit 1
        }
        USER_EMAIL="$2"
        shift 2
        ;;
      --list)
        LIST=1
        shift
        ;;
      --list-profiles)
        LIST_PROFILES=1
        shift
        ;;
      --list-features)
        LIST_FEATURES=1
        shift
        ;;
      --list-installers)
        LIST_INSTALLERS=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

prepare_interactive_mode() {
  if [[ "$YES" -eq 1 || "$AUTO" -eq 1 ]]; then
    export GET_BASHED_AUTO_APPROVE=1
  fi

  if [[ ! -t 0 ]] && [[ "$AUTO" -eq 0 ]]; then
    AUTO=1
  fi

  if [[ "$WITH_UI" -eq 1 ]] && [[ "$AUTO" -eq 0 ]] && [[ "$DRY_RUN" -eq 0 ]]; then
    install_dialog || true
  fi

  load_installers
  : "${INSTALLERS:=}"
}
