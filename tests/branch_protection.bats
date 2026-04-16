#!/usr/bin/env bats

load test_helper

@test "verify_branch_protection accepts the expected required status contexts" {
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
  query="${*: -1}"
  case "$query" in
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

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/verify_branch_protection.sh
  assert_success
  assert_output --partial "branch protection OK"

  rm -rf "$tmpdir"
}

@test "verify_branch_protection fails when the required contexts drift" {
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
  query="${*: -1}"
  case "$query" in
    *'contents/.github/workflows/codeql.yml?ref='*) exit 1 ;;
    *'.required_status_checks.contexts[]'*)
      printf '%s\n' \
        'Quality (ubuntu-latest)' \
        'Quality (macos-latest)' \
        'Docs Deployment'
      ;;
    *'.required_status_checks.strict'*) printf 'false\n' ;;
    *'.required_pull_request_reviews.required_approving_review_count'*) printf '0\n' ;;
    *'.required_pull_request_reviews.dismiss_stale_reviews'*) printf 'false\n' ;;
    *'.required_pull_request_reviews.require_code_owner_reviews'*) printf 'false\n' ;;
    *'.enforce_admins.enabled'*) printf 'false\n' ;;
    *'.required_linear_history.enabled'*) printf 'false\n' ;;
    *'.required_conversation_resolution.enabled'*) printf 'false\n' ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/verify_branch_protection.sh
  assert_failure
  assert_output --partial "expected 4 required checks"

  rm -rf "$tmpdir"
}

@test "verify_branch_protection adds repo-owned CodeQL checks once codeql.yml is live" {
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
  query="${*: -1}"
  case "$query" in
    *'contents/.github/workflows/codeql.yml?ref='*) exit 0 ;;
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

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/verify_branch_protection.sh
  assert_success
  assert_output --partial "branch protection OK"

  rm -rf "$tmpdir"
}
