#!/usr/bin/env bash

set -euo pipefail

REPO="${1:-jbcom/get-bashed}"
BRANCH="${2:-main}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required for branch protection verification" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh auth is required for branch protection verification" >&2
  exit 1
fi

expected_checks=(
  "Quality (ubuntu-latest)"
  "Quality (macos-latest)"
  "Quality (wsl-ubuntu)"
  "SonarQube Scan"
)

if gh api "repos/${REPO}/contents/.github/workflows/codeql.yml?ref=${BRANCH}" >/dev/null 2>&1; then
  expected_checks+=(
    "CodeQL (actions)"
    "CodeQL (python)"
  )
fi

mapfile -t actual_checks < <(
  gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_status_checks.contexts[]' \
    | LC_ALL=C sort
)

mapfile -t expected_sorted < <(printf '%s\n' "${expected_checks[@]}" | LC_ALL=C sort)

if [ "${#actual_checks[@]}" -ne "${#expected_sorted[@]}" ]; then
  printf 'expected %d required checks, found %d\n' "${#expected_sorted[@]}" "${#actual_checks[@]}" >&2
  printf 'actual: %s\n' "${actual_checks[*]-}" >&2
  exit 1
fi

for index in "${!expected_sorted[@]}"; do
  if [ "${expected_sorted[$index]}" != "${actual_checks[$index]}" ]; then
    printf 'required checks mismatch at index %s: expected %s got %s\n' \
      "$index" "${expected_sorted[$index]}" "${actual_checks[$index]}" >&2
    exit 1
  fi
done

actual_strict="$(gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_status_checks.strict')"
actual_reviews="$(gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_pull_request_reviews.required_approving_review_count')"
actual_dismiss_stale="$(gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_pull_request_reviews.dismiss_stale_reviews')"
actual_codeowners="$(gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_pull_request_reviews.require_code_owner_reviews')"
actual_admins="$(gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.enforce_admins.enabled')"
actual_linear_history="$(gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_linear_history.enabled')"
actual_conversation_resolution="$(gh api "repos/${REPO}/branches/${BRANCH}/protection" --jq '.required_conversation_resolution.enabled')"

if [ "$actual_strict" != "true" ]; then
  printf 'expected strict status checks, got %s\n' "$actual_strict" >&2
  exit 1
fi

if [ "$actual_reviews" != "1" ]; then
  printf 'expected 1 approving review, got %s\n' "$actual_reviews" >&2
  exit 1
fi

if [ "$actual_dismiss_stale" != "true" ]; then
  printf 'expected stale reviews to be dismissed, got %s\n' "$actual_dismiss_stale" >&2
  exit 1
fi

if [ "$actual_codeowners" != "true" ]; then
  printf 'expected code owner reviews enabled, got %s\n' "$actual_codeowners" >&2
  exit 1
fi

if [ "$actual_admins" != "true" ]; then
  printf 'expected admin enforcement enabled, got %s\n' "$actual_admins" >&2
  exit 1
fi

if [ "$actual_linear_history" != "true" ]; then
  printf 'expected linear history enabled, got %s\n' "$actual_linear_history" >&2
  exit 1
fi

if [ "$actual_conversation_resolution" != "true" ]; then
  printf 'expected conversation resolution enabled, got %s\n' "$actual_conversation_resolution" >&2
  exit 1
fi

printf 'branch protection OK for %s:%s\n' "${REPO}" "${BRANCH}"
