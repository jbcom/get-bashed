#!/usr/bin/env bats

load test_helper

@test "reconcile_codeql_governance refuses to retire default setup before codeql.yml is on the target branch" {
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
  case "$*" in
    *'contents/.github/workflows/codeql.yml?ref='*) exit 1 ;;
    *) exit 1 ;;
  esac
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/reconcile_codeql_governance.sh
  assert_failure
  assert_output --partial "codeql.yml must be present"

  rm -rf "$tmpdir"
}

@test "reconcile_codeql_governance retires default setup and patches required checks" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  state_file="$tmpdir/checks.txt"
  log_file="$tmpdir/gh.log"
  mkdir -p "$bindir"
  cat >"$state_file" <<'EOF'
Quality (ubuntu-latest)
Quality (macos-latest)
Quality (wsl-ubuntu)
SonarQube Scan
EOF

  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
state_file="$state_file"
log_file="$log_file"
if [[ "\$1 \$2" == "auth status" ]]; then
  exit 0
fi
if [[ "\$1" == "api" ]]; then
  case "\$*" in
    *'contents/.github/workflows/codeql.yml?ref='*)
      printf '{}\n'
      exit 0
      ;;
    *'repos/jbcom/get-bashed/code-scanning/default-setup'*'.state'*)
      printf 'configured\n'
      exit 0
      ;;
    *'-X PATCH repos/jbcom/get-bashed/code-scanning/default-setup'*)
      printf 'patched-default-setup\n' >> "\$log_file"
      exit 0
      ;;
    *'protection/required_status_checks'*'.strict'*)
      printf 'true\n'
      exit 0
      ;;
    *'protection/required_status_checks'*'.contexts[]'*)
      cat "\$state_file"
      exit 0
      ;;
    *'-X PATCH repos/jbcom/get-bashed/branches/main/protection/required_status_checks'*)
      printf '%s\n' "\$*" >> "\$log_file"
      {
        printf 'CodeQL (actions)\n'
        printf 'CodeQL (python)\n'
        cat "\$state_file"
      } | awk 'NF && !seen[\$0]++' | LC_ALL=C sort > "\$state_file.new"
      mv "\$state_file.new" "\$state_file"
      exit 0
      ;;
    *)
      exit 1
      ;;
  esac
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/reconcile_codeql_governance.sh
  assert_success
  assert_output --partial "retired GitHub default CodeQL setup"
  assert_output --partial "updated required status checks"

  run grep -F 'patched-default-setup' "$log_file"
  assert_success

  run grep -F 'contexts[]=CodeQL (actions)' "$log_file"
  assert_success

  run grep -F 'contexts[]=CodeQL (python)' "$log_file"
  assert_success

  rm -rf "$tmpdir"
}
