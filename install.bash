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

if [[ -n "${GET_BASHED_BOOTSTRAP_TMPDIR:-}" ]]; then
  trap 'rm -rf "$GET_BASHED_BOOTSTRAP_TMPDIR"' EXIT
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$REPO_DIR/installers/_helpers.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/installers/tools.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/installlib/config.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/installlib/resolve.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/installlib/ui.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/installlib/filesystem.sh"
# shellcheck disable=SC1091
source "$REPO_DIR/installlib/installers.sh"

main() {
  init_install_state
  parse_args "$@"
  prepare_interactive_mode
  resolve_requested_state
  handle_list_commands
  run_interactive_selection
  finalize_requested_state

  if [[ "$DRY_RUN" -eq 1 ]]; then
    print_dry_run_summary
    run_selected_installers
    exit 0
  fi

  install_managed_assets
  run_selected_installers

  echo "get-bashed installed to $PREFIX"
}

main "$@"
