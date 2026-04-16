#!/usr/bin/env bats

load test_helper

@test "supply_chain_verify passes against the checked-in repository" {
  run "$MODERN_BASH" ./scripts/supply_chain_verify.sh
  assert_success
  assert_output --partial "All supply chain checks passed"
}

@test "supply_chain_verify defers default-setup retirement until codeql.yml lands on main" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$bindir"

  cat >"$bindir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1 $2" == "auth status" ]]; then
  exit 0
fi
if [[ "$1" == "api" ]]; then
  args="$*"
  case "$args" in
    *'repos/jbcom/get-bashed/automated-security-fixes'*'.enabled'*) printf 'true\n' ;;
    *'repos/jbcom/get-bashed'*'dependabot_security_updates.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_push_protection.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_validity_checks.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_non_provider_patterns.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed/vulnerability-alerts'*) printf '{}\n' ;;
    *'repos/jbcom/get-bashed/contents/release-please-config.json?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/cd.yml?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/release.yml?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/codeql.yml?ref=main'*) exit 1 ;;
    *'contents/.github/workflows/codeql.yml?ref='*) exit 1 ;;
    *'.required_status_checks.contexts[]'*)
      printf '%s\n' \
        'Quality (ubuntu-latest)' \
        'Quality (macos-latest)' \
        'Quality (wsl-ubuntu)' \
        'SonarQube Scan'
      ;;
    *'.required_status_checks.strict'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.required_approving_review_count'*) printf '1\n' ;;
    *'.required_pull_request_reviews.dismiss_stale_reviews'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.require_code_owner_reviews'*) printf 'true\n' ;;
    *'.enforce_admins.enabled'*) printf 'true\n' ;;
    *'.required_linear_history.enabled'*) printf 'true\n' ;;
    *'.required_conversation_resolution.enabled'*) printf 'true\n' ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/supply_chain_verify.sh
  assert_success
  assert_output --partial "repo-owned CodeQL workflow is checked into the repository"
  assert_output --partial "live GitHub default CodeQL setup retirement will be checked after codeql.yml lands on main"

  rm -rf "$tmpdir"
}

@test "supply_chain_verify uses the resolved repo slug instead of a hard-coded upstream slug" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$bindir"

  cat >"$bindir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1 $2" == "auth status" ]]; then
  exit 0
fi
if [[ "$1" == "api" ]]; then
  args="$*"
  case "$args" in
    *'repos/acme/get-bashed-fork/automated-security-fixes'*'.enabled'*) printf 'true\n' ;;
    *'repos/acme/get-bashed-fork'*'dependabot_security_updates.status'*) printf 'enabled\n' ;;
    *'repos/acme/get-bashed-fork'*'secret_scanning.status'*) printf 'enabled\n' ;;
    *'repos/acme/get-bashed-fork'*'secret_scanning_push_protection.status'*) printf 'enabled\n' ;;
    *'repos/acme/get-bashed-fork'*'secret_scanning_validity_checks.status'*) printf 'enabled\n' ;;
    *'repos/acme/get-bashed-fork'*'secret_scanning_non_provider_patterns.status'*) printf 'enabled\n' ;;
    *'repos/acme/get-bashed-fork/vulnerability-alerts'*) printf '{}\n' ;;
    *'repos/acme/get-bashed-fork/contents/.github/workflows/codeql.yml?ref=main'*) exit 1 ;;
    *'.required_status_checks.contexts[]'*)
      printf '%s\n' \
        'Quality (ubuntu-latest)' \
        'Quality (macos-latest)' \
        'Quality (wsl-ubuntu)' \
        'SonarQube Scan'
      ;;
    *'.required_status_checks.strict'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.required_approving_review_count'*) printf '1\n' ;;
    *'.required_pull_request_reviews.dismiss_stale_reviews'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.require_code_owner_reviews'*) printf 'true\n' ;;
    *'.enforce_admins.enabled'*) printf 'true\n' ;;
    *'.required_linear_history.enabled'*) printf 'true\n' ;;
    *'.required_conversation_resolution.enabled'*) printf 'true\n' ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env GET_BASHED_REPO_SLUG="acme/get-bashed-fork" PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/supply_chain_verify.sh
  assert_success
  assert_output --partial "All supply chain checks passed"

  rm -rf "$tmpdir"
}

@test "supply_chain_verify fails when main has codeql.yml but default setup is still enabled" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$bindir"

  cat >"$bindir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1 $2" == "auth status" ]]; then
  exit 0
fi
if [[ "$1" == "api" ]]; then
  args="$*"
  case "$args" in
    *'repos/jbcom/get-bashed/automated-security-fixes'*'.enabled'*) printf 'true\n' ;;
    *'repos/jbcom/get-bashed'*'dependabot_security_updates.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_push_protection.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_validity_checks.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_non_provider_patterns.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed/vulnerability-alerts'*) printf '{}\n' ;;
    *'repos/jbcom/get-bashed/contents/release-please-config.json?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/cd.yml?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/release.yml?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/codeql.yml?ref=main'*) printf '{}\n' ;;
    *'repos/jbcom/get-bashed/code-scanning/default-setup'*'.state'*) printf 'configured\n' ;;
    *'contents/.github/workflows/codeql.yml?ref='*) printf '{}\n' ;;
    *'.required_status_checks.contexts[]'*)
      printf '%s\n' \
        'CodeQL (actions)' \
        'CodeQL (python)' \
        'Quality (ubuntu-latest)' \
        'Quality (macos-latest)' \
        'Quality (wsl-ubuntu)' \
        'SonarQube Scan'
      ;;
    *'.required_status_checks.strict'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.required_approving_review_count'*) printf '1\n' ;;
    *'.required_pull_request_reviews.dismiss_stale_reviews'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.require_code_owner_reviews'*) printf 'true\n' ;;
    *'.enforce_admins.enabled'*) printf 'true\n' ;;
    *'.required_linear_history.enabled'*) printf 'true\n' ;;
    *'.required_conversation_resolution.enabled'*) printf 'true\n' ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/supply_chain_verify.sh
  assert_failure
  assert_output --partial "live GitHub default CodeQL setup is still enabled after codeql.yml landed on main"

  rm -rf "$tmpdir"
}

@test "supply_chain_verify fails when secret scanning protections drift" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$bindir"

  cat >"$bindir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1 $2" == "auth status" ]]; then
  exit 0
fi
if [[ "$1" == "api" ]]; then
  args="$*"
  case "$args" in
    *'repos/jbcom/get-bashed/automated-security-fixes'*'.enabled'*) printf 'true\n' ;;
    *'repos/jbcom/get-bashed'*'dependabot_security_updates.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning.status'*) printf 'disabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_push_protection.status'*) printf 'disabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_validity_checks.status'*) printf 'disabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_non_provider_patterns.status'*) printf 'disabled\n' ;;
    *'repos/jbcom/get-bashed/vulnerability-alerts'*) printf '{}\n' ;;
    *'repos/jbcom/get-bashed/contents/release-please-config.json?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/cd.yml?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/release.yml?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/codeql.yml?ref=main'*) exit 1 ;;
    *'contents/.github/workflows/codeql.yml?ref='*) exit 1 ;;
    *'.required_status_checks.contexts[]'*)
      printf '%s\n' \
        'Quality (ubuntu-latest)' \
        'Quality (macos-latest)' \
        'Quality (wsl-ubuntu)' \
        'SonarQube Scan'
      ;;
    *'.required_status_checks.strict'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.required_approving_review_count'*) printf '1\n' ;;
    *'.required_pull_request_reviews.dismiss_stale_reviews'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.require_code_owner_reviews'*) printf 'true\n' ;;
    *'.enforce_admins.enabled'*) printf 'true\n' ;;
    *'.required_linear_history.enabled'*) printf 'true\n' ;;
    *'.required_conversation_resolution.enabled'*) printf 'true\n' ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/supply_chain_verify.sh
  assert_failure
  assert_output --partial "secret scanning is disabled"
  assert_output --partial "secret scanning push protection is disabled"
  assert_output --partial "secret scanning validity checks are disabled"
  assert_output --partial "non-provider secret scanning patterns are disabled"

  rm -rf "$tmpdir"
}

@test "supply_chain_verify fails when immutable releases stay disabled after draft-first rollout" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$bindir"

  release_config_b64="$(python3 - <<'PY'
import base64
payload = '{\n  "draft": true,\n  "force-tag-creation": true\n}\n'
print(base64.b64encode(payload.encode()).decode())
PY
)"
  cd_workflow_b64="$(python3 - <<'PY'
import base64
payload = '''- id: release
  uses: googleapis/release-please-action@deadbeef
  with:
    token: ${{ secrets.CI_GITHUB_TOKEN || github.token }}
- if: steps.release.outputs.release_created
  run: bash scripts/publish_draft_release.sh
'''
print(base64.b64encode(payload.encode()).decode())
PY
)"
  release_workflow_b64="$(python3 - <<'PY'
import base64
payload = '''on:
  workflow_dispatch:
    inputs:
      publish_release:
jobs:
  publish:
    steps:
      - run: bash scripts/publish_draft_release.sh
      - run: bash scripts/verify_published_release.sh
      - run: bash scripts/publish_pkg_pr.sh
'''
print(base64.b64encode(payload.encode()).decode())
PY
)"

  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\$1 \$2" == "auth status" ]]; then
  exit 0
fi
if [[ "\$1" == "api" ]]; then
  args="\$*"
  case "\$args" in
    *'repos/jbcom/get-bashed/automated-security-fixes'*'.enabled'*) printf 'true\n' ;;
    *'repos/jbcom/get-bashed'*'dependabot_security_updates.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_push_protection.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_validity_checks.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed'*'secret_scanning_non_provider_patterns.status'*) printf 'enabled\n' ;;
    *'repos/jbcom/get-bashed/vulnerability-alerts'*) printf '{}\n' ;;
    *'repos/jbcom/get-bashed/contents/release-please-config.json?ref=main'*) printf '%s\n' "$release_config_b64" ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/cd.yml?ref=main'*) printf '%s\n' "$cd_workflow_b64" ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/release.yml?ref=main'*) printf '%s\n' "$release_workflow_b64" ;;
    *'repos/jbcom/get-bashed/contents/.github/workflows/codeql.yml?ref=main'*) exit 1 ;;
    *'repos/jbcom/get-bashed/immutable-releases'*'.enabled'*) printf 'false\n' ;;
    *'contents/.github/workflows/codeql.yml?ref='*) exit 1 ;;
    *'.required_status_checks.contexts[]'*)
      printf '%s\n' \
        'Quality (ubuntu-latest)' \
        'Quality (macos-latest)' \
        'Quality (wsl-ubuntu)' \
        'SonarQube Scan'
      ;;
    *'.required_status_checks.strict'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.required_approving_review_count'*) printf '1\n' ;;
    *'.required_pull_request_reviews.dismiss_stale_reviews'*) printf 'true\n' ;;
    *'.required_pull_request_reviews.require_code_owner_reviews'*) printf 'true\n' ;;
    *'.enforce_admins.enabled'*) printf 'true\n' ;;
    *'.required_linear_history.enabled'*) printf 'true\n' ;;
    *'.required_conversation_resolution.enabled'*) printf 'true\n' ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/supply_chain_verify.sh
  assert_failure
  assert_output --partial "immutable release governance does not match the draft-first release policy"

  rm -rf "$tmpdir"
}
