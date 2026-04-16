#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090,SC1091
. "$SCRIPT_DIR/lib/immutable_release_flow.sh"

REPO="${1:-jbcom/get-bashed}"
BRANCH="${2:-main}"

immutable_release_require_gh

if ! immutable_release_branch_ready "$REPO" "$BRANCH"; then
  printf 'immutable release governance check deferred until draft-first release flow lands on %s:%s\n' \
    "$REPO" "$BRANCH"
  exit 0
fi

immutable_enabled="$(gh api "repos/${REPO}/immutable-releases" --jq '.enabled' 2>/dev/null || printf 'false')"
if [ "$immutable_enabled" = "true" ]; then
  printf 'immutable releases enabled for %s:%s\n' "$REPO" "$BRANCH"
  exit 0
fi

printf 'immutable releases are not enabled after the draft-first release flow landed on %s:%s\n' \
  "$REPO" "$BRANCH" >&2
exit 1
