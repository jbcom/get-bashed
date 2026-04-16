#!/usr/bin/env bats

load test_helper

encode_text() {
  python3 - <<'PY' "$1"
import base64
import sys

print(base64.b64encode(sys.argv[1].encode("utf-8")).decode("ascii"))
PY
}

@test "verify_immutable_release_governance defers until the draft-first flow is on the target branch" {
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
    *'contents/release-please-config.json?ref='*) exit 1 ;;
    *) exit 1 ;;
  esac
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/verify_immutable_release_governance.sh
  assert_success
  assert_output --partial "deferred until draft-first release flow lands"

  rm -rf "$tmpdir"
}

@test "verify_immutable_release_governance fails when immutable releases remain disabled after rollout" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$bindir"

  release_config_b64="$(encode_text "$(cat <<'EOF'
{
  "draft": true,
  "force-tag-creation": true
}
EOF
)")"
  cd_workflow_b64="$(encode_text "$(cat <<'EOF'
- id: release
  uses: googleapis/release-please-action@deadbeef
  with:
    token: ${{ secrets.CI_GITHUB_TOKEN || github.token }}
- if: steps.release.outputs.release_created
  run: bash scripts/publish_draft_release.sh
EOF
)")"
  release_workflow_b64="$(encode_text "$(cat <<'EOF'
on:
  workflow_dispatch:
    inputs:
      publish_release:
jobs:
  publish:
    steps:
      - run: bash scripts/publish_draft_release.sh
      - run: bash scripts/verify_published_release.sh
      - run: bash scripts/publish_pkg_pr.sh
EOF
)")"

  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
if [[ "\$1 \$2" == "auth status" ]]; then
  exit 0
fi
if [[ "\$1" == "api" ]]; then
  case "\$*" in
    *'contents/release-please-config.json?ref='*) printf '%s\n' "$release_config_b64" ;;
    *'contents/.github/workflows/cd.yml?ref='*) printf '%s\n' "$cd_workflow_b64" ;;
    *'contents/.github/workflows/release.yml?ref='*) printf '%s\n' "$release_workflow_b64" ;;
    *'repos/jbcom/get-bashed/immutable-releases'*'.enabled'*) printf 'false\n' ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/verify_immutable_release_governance.sh
  assert_failure
  assert_output --partial "immutable releases are not enabled"

  rm -rf "$tmpdir"
}

@test "reconcile_immutable_release_governance refuses before draft-first flow is live" {
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
    *'contents/release-please-config.json?ref='*) exit 1 ;;
    *) exit 1 ;;
  esac
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/reconcile_immutable_release_governance.sh
  assert_failure
  assert_output --partial "draft-first release flow must be present"

  rm -rf "$tmpdir"
}

@test "reconcile_immutable_release_governance enables immutable releases once rollout is live" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  log_file="$tmpdir/gh.log"
  mkdir -p "$bindir"

  release_config_b64="$(encode_text "$(cat <<'EOF'
{
  "draft": true,
  "force-tag-creation": true
}
EOF
)")"
  cd_workflow_b64="$(encode_text "$(cat <<'EOF'
- id: release
  uses: googleapis/release-please-action@deadbeef
  with:
    token: ${{ secrets.CI_GITHUB_TOKEN || github.token }}
- if: steps.release.outputs.release_created
  run: bash scripts/publish_draft_release.sh
EOF
)")"
  release_workflow_b64="$(encode_text "$(cat <<'EOF'
on:
  workflow_dispatch:
    inputs:
      publish_release:
jobs:
  publish:
    steps:
      - run: bash scripts/publish_draft_release.sh
      - run: bash scripts/verify_published_release.sh
      - run: bash scripts/publish_pkg_pr.sh
EOF
)")"

  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$log_file"
if [[ "\$1 \$2" == "auth status" ]]; then
  exit 0
fi
if [[ "\$1" == "api" ]]; then
  case "\$*" in
    *'contents/release-please-config.json?ref='*) printf '%s\n' "$release_config_b64" ;;
    *'contents/.github/workflows/cd.yml?ref='*) printf '%s\n' "$cd_workflow_b64" ;;
    *'contents/.github/workflows/release.yml?ref='*) printf '%s\n' "$release_workflow_b64" ;;
    *'repos/jbcom/get-bashed/immutable-releases'*'.enabled'*) printf 'false\n' ;;
    *'-X PUT repos/jbcom/get-bashed/immutable-releases'*) exit 0 ;;
    *) exit 1 ;;
  esac
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/reconcile_immutable_release_governance.sh
  assert_success
  assert_output --partial "enabled immutable releases"

  run grep -F 'api -X PUT repos/jbcom/get-bashed/immutable-releases' "$log_file"
  assert_success

  rm -rf "$tmpdir"
}
