#!/usr/bin/env bash

IMMUTABLE_RELEASE_PYTHON_BIN="${PYTHON:-$(command -v python3 || command -v python || true)}"

immutable_release_require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI is required for immutable release governance checks" >&2
    exit 1
  fi

  if [ -z "$IMMUTABLE_RELEASE_PYTHON_BIN" ]; then
    echo "python3 or python is required for immutable release governance checks" >&2
    exit 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "gh auth is required for immutable release governance checks" >&2
    exit 1
  fi
}

immutable_release_fetch_repo_file() {
  local repo="$1"
  local branch="$2"
  local path="$3"

  gh api "repos/${repo}/contents/${path}?ref=${branch}" --jq '.content' \
    | tr -d '\n' \
    | "$IMMUTABLE_RELEASE_PYTHON_BIN" -c '
import base64
import sys

payload = sys.stdin.read().strip()
if not payload:
    raise SystemExit(1)

sys.stdout.write(base64.b64decode(payload).decode("utf-8"))
'
}

immutable_release_branch_ready() {
  local repo="$1"
  local branch="$2"
  local release_config=""
  local cd_workflow=""
  local release_workflow=""

  release_config="$(immutable_release_fetch_repo_file "$repo" "$branch" "release-please-config.json" 2>/dev/null || true)"
  cd_workflow="$(immutable_release_fetch_repo_file "$repo" "$branch" ".github/workflows/cd.yml" 2>/dev/null || true)"
  release_workflow="$(immutable_release_fetch_repo_file "$repo" "$branch" ".github/workflows/release.yml" 2>/dev/null || true)"

  [ -n "$release_config" ] || return 1
  [ -n "$cd_workflow" ] || return 1
  [ -n "$release_workflow" ] || return 1

  [[ "$release_config" == *'"draft": true'* ]] || return 1
  [[ "$release_config" == *'"force-tag-creation": true'* ]] || return 1

  [[ "$cd_workflow" == *'id: release'* ]] || return 1
  [[ "$cd_workflow" == *'scripts/publish_draft_release.sh'* ]] || return 1

  [[ "$release_workflow" == *'workflow_dispatch:'* ]] || return 1
  [[ "$release_workflow" == *'scripts/publish_draft_release.sh'* ]] || return 1
  [[ "$release_workflow" != *'types: [published]'* ]] || return 1
}
