#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required=(
  "$REPO_ROOT/docs/conf.py"
  "$REPO_ROOT/docs/index.md"
  "$REPO_ROOT/docs/getting-started/index.md"
  "$REPO_ROOT/docs/getting-started/downloads.md"
  "$REPO_ROOT/docs/getting-started/install-and-verify.md"
  "$REPO_ROOT/docs/reference/index.md"
  "$REPO_ROOT/docs/reference/architecture.md"
  "$REPO_ROOT/docs/reference/security.md"
  "$REPO_ROOT/docs/reference/testing.md"
  "$REPO_ROOT/docs/reference/supply-chain.md"
  "$REPO_ROOT/docs/reference/release-checklist.md"
  "$REPO_ROOT/docs/reference/release-verification.md"
  "$REPO_ROOT/docs/api/index.md"
  "$REPO_ROOT/docs/public/install.sh"
  "$REPO_ROOT/scripts/build_release_artifact.sh"
  "$REPO_ROOT/scripts/generate_pkg_manifests.sh"
  "$REPO_ROOT/scripts/release_validate.sh"
  "$REPO_ROOT/scripts/verify_published_release.sh"
  "$REPO_ROOT/scripts/publish_pkg_pr.sh"
  "$REPO_ROOT/scripts/verify_branch_protection.sh"
  "$REPO_ROOT/scripts/supply_chain_verify.sh"
)

for file in "${required[@]}"; do
  test -f "$file"
done

grep -q "getting-started/index" "$REPO_ROOT/docs/index.md"
grep -q "reference/index" "$REPO_ROOT/docs/index.md"
grep -q "api/index" "$REPO_ROOT/docs/index.md"
grep -q "get-bashed-<version>-unix.tar.gz" "$REPO_ROOT/docs/getting-started/index.md"
grep -q "get-bashed-<version>-windows.zip" "$REPO_ROOT/docs/getting-started/downloads.md"
grep -q "jbcom/pkgs" "$REPO_ROOT/docs/getting-started/downloads.md"
grep -q "verify-published-release" "$REPO_ROOT/docs/reference/release-verification.md"
grep -q "verify-branch-protection" "$REPO_ROOT/docs/reference/release-verification.md"
grep -q "verify-branch-protection" "$REPO_ROOT/docs/reference/release-checklist.md"
grep -q "verify-security" "$REPO_ROOT/docs/TESTING.md"
grep -q "verify-security" "$REPO_ROOT/docs/reference/security.md"
grep -q "release-validate" "$REPO_ROOT/docs/reference/release-checklist.md"
grep -q "INSTALLERS_HELPERS" "$REPO_ROOT/docs/api/index.md"
