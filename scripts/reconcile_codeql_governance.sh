#!/usr/bin/env bash

set -euo pipefail

REPO="${1:-jbcom/get-bashed}"
BRANCH="${2:-main}"

required_codeql_checks=(
  "CodeQL (actions)"
  "CodeQL (python)"
)

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required for CodeQL governance reconciliation" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh auth is required for CodeQL governance reconciliation" >&2
  exit 1
fi

if ! gh api "repos/${REPO}/contents/.github/workflows/codeql.yml?ref=${BRANCH}" >/dev/null 2>&1; then
  echo "codeql.yml must be present on ${REPO}:${BRANCH} before retiring default setup" >&2
  exit 1
fi

default_state="$(gh api "repos/${REPO}/code-scanning/default-setup" --jq '.state')"
if [ "$default_state" != "not-configured" ]; then
  gh api -X PATCH "repos/${REPO}/code-scanning/default-setup" -f state='not-configured' >/dev/null
  echo "retired GitHub default CodeQL setup for ${REPO}"
else
  echo "GitHub default CodeQL setup already retired for ${REPO}"
fi

strict="$(gh api "repos/${REPO}/branches/${BRANCH}/protection/required_status_checks" --jq '.strict')"
mapfile -t current_contexts < <(
  gh api "repos/${REPO}/branches/${BRANCH}/protection/required_status_checks" --jq '.contexts[]'
)

mapfile -t merged_contexts < <(
  printf '%s\n' "${current_contexts[@]}" "${required_codeql_checks[@]}" \
    | awk 'NF && !seen[$0]++' \
    | LC_ALL=C sort
)

patch_args=(
  api
  -X PATCH
  "repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"
  -F "strict=${strict}"
)

for context in "${merged_contexts[@]}"; do
  patch_args+=(-f "contexts[]=${context}")
done

gh "${patch_args[@]}" >/dev/null

printf 'updated required status checks for %s:%s\n' "${REPO}" "${BRANCH}"
printf 'required checks now include: %s\n' "${required_codeql_checks[*]}"
printf 'next: bash ./scripts/verify_branch_protection.sh %s %s\n' "${REPO}" "${BRANCH}"
