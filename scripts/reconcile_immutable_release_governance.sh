#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090,SC1091
. "$SCRIPT_DIR/lib/immutable_release_flow.sh"

REPO="${1:-jbcom/get-bashed}"
BRANCH="${2:-main}"

immutable_release_require_gh

if ! immutable_release_branch_ready "$REPO" "$BRANCH"; then
  printf 'draft-first release flow must be present on %s:%s before enabling immutable releases\n' \
    "$REPO" "$BRANCH" >&2
  exit 1
fi

immutable_enabled="$(gh api "repos/${REPO}/immutable-releases" --jq '.enabled' 2>/dev/null || printf 'false')"
if [ "$immutable_enabled" != "true" ]; then
  gh api -X PUT "repos/${REPO}/immutable-releases" >/dev/null
  printf 'enabled immutable releases for %s:%s\n' "$REPO" "$BRANCH"
else
  printf 'immutable releases already enabled for %s:%s\n' "$REPO" "$BRANCH"
fi

printf 'next: bash ./scripts/verify_immutable_release_governance.sh %s %s\n' "$REPO" "$BRANCH"
