#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/supply_chain_common.sh"

failed=0

pass() {
  printf "%bPASS%b %s\n" "$GREEN" "$NC" "$1"
}

fail() {
  printf "%bFAIL%b %s\n" "$RED" "$NC" "$1"
  failed=1
}

echo
echo "get-bashed Supply Chain Verification"
echo

workflow_dir="$REPO_ROOT/.github/workflows"
if [ -d "$workflow_dir" ]; then
  external_uses=$(grep -rE '^[[:space:]]*uses:' "$workflow_dir"/*.yml | grep -v 'uses:[[:space:]]\+\./' || true)
  if [ -z "$external_uses" ] || ! printf '%s\n' "$external_uses" | grep -vE '@[a-f0-9]{40}' >/dev/null; then
    pass "external GitHub Actions are SHA-pinned"
  else
    fail "one or more external GitHub Actions are not SHA-pinned"
  fi
else
  fail "workflow directory missing"
fi

permission_locked_workflows=(
  "$REPO_ROOT/.github/workflows/ci.yml"
  "$REPO_ROOT/.github/workflows/codeql.yml"
  "$REPO_ROOT/.github/workflows/cd.yml"
  "$REPO_ROOT/.github/workflows/release.yml"
  "$REPO_ROOT/.github/workflows/scorecard.yml"
  "$REPO_ROOT/.github/workflows/automerge.yml"
)

workflow_permissions_ok="true"
for workflow in "${permission_locked_workflows[@]}"; do
  if ! has_regex '^permissions: \{\}$' "$workflow"; then
    workflow_permissions_ok="false"
    break
  fi
done

if [ "$workflow_permissions_ok" = "true" ]; then
  pass "workflows declare explicit top-level least-privilege permissions"
else
  fail "one or more workflows are missing top-level permissions lockdown"
fi

if [ -f "$REPO_ROOT/installers/bootstrap_sources.sh" ] \
  && [ -f "$REPO_ROOT/installers/sources.sh" ] \
  && ! has_regex 'archive/refs/heads/.+\.tar\.gz|raw\.githubusercontent\.com/.+/HEAD/' \
    "$REPO_ROOT/install.sh" \
    "$REPO_ROOT/installers/bootstrap_sources.sh" \
    "$REPO_ROOT/installers/sources.sh"; then
  pass "bootstrap and fallback download sources are pinned"
else
  fail "bootstrap or fallback download sources are not fully pinned"
fi

if has_regex 'GET_BASHED_ACTIONLINT_SHA256\["linux_amd64"\]' "$REPO_ROOT/installers/sources.sh" \
  && has_regex 'GET_BASHED_ACTIONLINT_SHA256\["darwin_arm64"\]' "$REPO_ROOT/installers/sources.sh"; then
  pass "actionlint fallback includes pinned per-platform checksums"
else
  fail "actionlint fallback checksums are incomplete"
fi

if [ -f "$REPO_ROOT/docs/public/install.sh" ] \
  && [ -f "$REPO_ROOT/scripts/release_validate.sh" ] \
  && [ -f "$REPO_ROOT/scripts/publish_draft_release.sh" ] \
  && [ -f "$REPO_ROOT/scripts/verify_published_release.sh" ] \
  && [ -f "$REPO_ROOT/scripts/publish_pkg_pr.sh" ]; then
  pass "release installer and publication scripts are checked into the repo"
else
  fail "release installer or publication scripts are missing"
fi

if has_regex '"draft":[[:space:]]*true' "$REPO_ROOT/release-please-config.json" \
  && has_regex '"force-tag-creation":[[:space:]]*true' "$REPO_ROOT/release-please-config.json"; then
  pass "release-please is configured for draft-first releases with eager tag creation"
else
  fail "release-please draft-first or force-tag-creation settings are missing"
fi

release_workflow="$REPO_ROOT/.github/workflows/release.yml"
cd_workflow="$REPO_ROOT/.github/workflows/cd.yml"
if [ -f "$release_workflow" ] \
  && [ -f "$cd_workflow" ] \
  && has_regex 'steps.release.outputs.release_created' "$cd_workflow" \
  && has_regex 'scripts/publish_draft_release\.sh' "$cd_workflow" \
  && has_regex 'secrets.CI_GITHUB_TOKEN \|\| github.token' "$cd_workflow" \
  && has_regex 'scripts/build_release_artifact\.sh' "$release_workflow" \
  && has_regex 'scripts/release_validate\.sh' "$release_workflow" \
  && has_regex 'scripts/publish_draft_release\.sh' "$release_workflow" \
  && has_regex 'scripts/verify_published_release\.sh' "$release_workflow" \
  && has_regex 'scripts/publish_pkg_pr\.sh' "$release_workflow" \
  && has_regex 'workflow_dispatch:' "$release_workflow" \
  && ! has_regex 'types: \[published\]' "$release_workflow" \
  && ! has_regex '\|\| true' "$release_workflow"; then
  pass "release workflows use repo-owned draft-first validation and publication scripts"
else
  fail "release workflows are missing repo-owned draft-first validation/publication steps or swallow failures"
fi

if [ -f "$REPO_ROOT/.github/workflows/scorecard.yml" ] \
  && has_regex 'ossf/scorecard-action@' "$REPO_ROOT/.github/workflows/scorecard.yml"; then
  pass "Scorecard workflow is present as a separate security signal"
else
  fail "Scorecard workflow is missing"
fi

codeql_workflow="$REPO_ROOT/.github/workflows/codeql.yml"
if [ -f "$codeql_workflow" ] \
  && has_regex '^name: CodeQL$' "$codeql_workflow" \
  && has_regex 'language: \[actions, python\]' "$codeql_workflow" \
  && has_regex 'queries: security-extended' "$codeql_workflow" \
  && has_regex 'github/codeql-action/init@' "$codeql_workflow" \
  && has_regex 'github/codeql-action/autobuild@' "$codeql_workflow" \
  && has_regex 'github/codeql-action/analyze@' "$codeql_workflow"; then
  pass "repo-owned CodeQL workflow is checked into the repository"
else
  fail "repo-owned CodeQL workflow is missing or incomplete"
fi

if [ -f "$REPO_ROOT/.github/dependabot.yml" ] \
  && has_regex 'package-ecosystem: "github-actions"' "$REPO_ROOT/.github/dependabot.yml"; then
  pass "Dependabot configuration is checked into the repo"
else
  fail "Dependabot configuration is missing or incomplete"
fi

if has_regex 'docs-linkcheck' "$REPO_ROOT/tox.ini" \
  && has_regex 'uvx tox -e docs,docs-linkcheck' "$REPO_ROOT/.github/workflows/ci.yml"; then
  pass "docs link validation is wired into tox and CI"
else
  fail "docs link validation is missing from tox or CI"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  repo_slug="$(resolve_repo_slug)"
  automated_security_fixes_enabled="$(gh api "repos/${repo_slug}/automated-security-fixes" --jq '.enabled' 2>/dev/null || printf 'false')"
  vulnerability_alerts_enabled="false"
  if gh api "repos/${repo_slug}/vulnerability-alerts" -H 'Accept: application/vnd.github+json' >/dev/null 2>&1; then
    vulnerability_alerts_enabled="true"
  fi
  dependabot_security_updates_enabled="$(gh api "repos/${repo_slug}" --jq '.security_and_analysis.dependabot_security_updates.status' 2>/dev/null || printf 'disabled')"
  secret_scanning_enabled="$(gh api "repos/${repo_slug}" --jq '.security_and_analysis.secret_scanning.status' 2>/dev/null || printf 'disabled')"
  push_protection_enabled="$(gh api "repos/${repo_slug}" --jq '.security_and_analysis.secret_scanning_push_protection.status' 2>/dev/null || printf 'disabled')"
  validity_checks_enabled="$(gh api "repos/${repo_slug}" --jq '.security_and_analysis.secret_scanning_validity_checks.status' 2>/dev/null || printf 'disabled')"
  non_provider_patterns_enabled="$(gh api "repos/${repo_slug}" --jq '.security_and_analysis.secret_scanning_non_provider_patterns.status' 2>/dev/null || printf 'disabled')"
  live_codeql_workflow="false"
  if gh api "repos/${repo_slug}/contents/.github/workflows/codeql.yml?ref=main" >/dev/null 2>&1; then
    live_codeql_workflow="true"
  fi
  if [ "$live_codeql_workflow" = "true" ]; then
    live_codeql_default_state="$(gh api "repos/${repo_slug}/code-scanning/default-setup" --jq '.state' 2>/dev/null || printf 'unknown')"
    if [ "$live_codeql_default_state" = "not-configured" ]; then
      pass "live GitHub default CodeQL setup is disabled in favor of the repo-owned workflow"
    else
      fail "live GitHub default CodeQL setup is still enabled after codeql.yml landed on main"
    fi
  else
    pass "live GitHub default CodeQL setup retirement will be checked after codeql.yml lands on main"
  fi

  if [ "$automated_security_fixes_enabled" = "true" ]; then
    pass "automated Dependabot security fixes are enabled"
  else
    fail "automated Dependabot security fixes are disabled"
  fi

  if [ "$vulnerability_alerts_enabled" = "true" ]; then
    pass "vulnerability alerts are enabled"
  else
    fail "vulnerability alerts are disabled"
  fi

  if [ "$dependabot_security_updates_enabled" = "enabled" ]; then
    pass "Dependabot security updates are enabled in repository security settings"
  else
    fail "Dependabot security updates are disabled in repository security settings"
  fi

  if [ "$secret_scanning_enabled" = "enabled" ]; then
    pass "secret scanning is enabled"
  else
    fail "secret scanning is disabled"
  fi

  if [ "$push_protection_enabled" = "enabled" ]; then
    pass "secret scanning push protection is enabled"
  else
    fail "secret scanning push protection is disabled"
  fi

  if [ "$validity_checks_enabled" = "enabled" ]; then
    pass "secret scanning validity checks are enabled"
  else
    fail "secret scanning validity checks are disabled"
  fi

  if [ "$non_provider_patterns_enabled" = "enabled" ]; then
    pass "non-provider secret scanning patterns are enabled"
  else
    fail "non-provider secret scanning patterns are disabled"
  fi
else
  pass "live GitHub security settings checks skipped: gh auth unavailable"
fi

if [ -f "$REPO_ROOT/scripts/verify_branch_protection.sh" ] \
  && has_regex '^verify-branch-protection:' "$REPO_ROOT/Makefile"; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    if bash "$REPO_ROOT/scripts/verify_branch_protection.sh" >/dev/null; then
      pass "branch protection matches the documented required CI contexts"
    else
      fail "branch protection does not match the documented required CI contexts"
    fi
  else
    pass "branch protection verification is present (live check skipped: gh auth unavailable)"
  fi
else
  fail "branch protection verification is missing"
fi

if [ -f "$REPO_ROOT/scripts/reconcile_codeql_governance.sh" ] \
  && has_regex '^reconcile-codeql-governance:' "$REPO_ROOT/Makefile"; then
  pass "post-merge CodeQL governance reconciliation is scripted in the repo"
else
  fail "post-merge CodeQL governance reconciliation is missing"
fi

if [ -f "$REPO_ROOT/scripts/verify_immutable_release_governance.sh" ] \
  && [ -f "$REPO_ROOT/scripts/reconcile_immutable_release_governance.sh" ] \
  && has_regex '^verify-immutable-release-governance:' "$REPO_ROOT/Makefile" \
  && has_regex '^reconcile-immutable-release-governance:' "$REPO_ROOT/Makefile"; then
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    if bash "$REPO_ROOT/scripts/verify_immutable_release_governance.sh" >/dev/null; then
      pass "immutable release governance is scripted and verified"
    else
      fail "immutable release governance does not match the draft-first release policy"
    fi
  else
    pass "immutable release governance is scripted (live check skipped: gh auth unavailable)"
  fi
else
  fail "immutable release governance verification or reconciliation is missing"
fi

if has_regex '^verify-security:' "$REPO_ROOT/Makefile" \
  && has_regex 'make verify-security' "$REPO_ROOT/README.md" \
  && has_regex 'make verify-security' "$REPO_ROOT/docs/TESTING.md" \
  && has_regex 'make verify-security' "$REPO_ROOT/docs/reference/security.md"; then
  pass "security verification is exposed through make and documented"
else
  fail "security verification target or docs are missing"
fi

if [ "$failed" -ne 0 ]; then
  echo
  printf "%bSupply chain verification failed%b\n" "$RED" "$NC"
  exit 1
fi

echo
printf "%bAll supply chain checks passed%b\n" "$GREEN" "$NC"
