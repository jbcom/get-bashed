#!/usr/bin/env bats

load test_helper

pick_port() {
  python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
}

wait_for_http() {
  local url="$1"
  local _
  for _ in $(seq 1 50); do
    if python3 - "$url" <<'PY' >/dev/null 2>&1
from urllib.request import urlopen
import sys

with urlopen(sys.argv[1], timeout=1):
    pass
PY
    then
      return 0
    fi
    sleep 0.1
  done

  return 1
}

@test "release artifacts build and smoke test successfully" {
  tmpdir="$(mktemp -d)"

  run "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.9 "$tmpdir"
  assert_success

  assert_file_exist "$tmpdir/get-bashed-9.9.9-unix.tar.gz"
  assert_file_exist "$tmpdir/get-bashed-9.9.9-unix.tar.gz.sha256"
  assert_file_exist "$tmpdir/get-bashed-9.9.9-windows.zip"
  assert_file_exist "$tmpdir/get-bashed-9.9.9-windows.zip.sha256"

  run tar -tzf "$tmpdir/get-bashed-9.9.9-unix.tar.gz"
  assert_success
  refute_output --partial "__pycache__"
  refute_output --partial ".pyc"

  run python3 - <<'PY' "$tmpdir/get-bashed-9.9.9-windows.zip"
from zipfile import ZipFile
import sys

with ZipFile(sys.argv[1]) as bundle:
    for name in bundle.namelist():
        print(name)
PY
  assert_success
  refute_output --partial "__pycache__"
  refute_output --partial ".pyc"

  run "$MODERN_BASH" ./scripts/smoke_test_release_artifact.sh 9.9.9 "$tmpdir/get-bashed-9.9.9-unix.tar.gz"
  assert_success

  run "$MODERN_BASH" ./scripts/smoke_test_release_artifact.sh 9.9.9 "$tmpdir/get-bashed-9.9.9-windows.zip"
  assert_success

  rm -rf "$tmpdir"
}

@test "publish_draft_release uploads assets to a draft release and publishes it" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  state_file="$tmpdir/state"
  log="$tmpdir/gh.log"
  mkdir -p "$bindir" "$tmpdir/dist"
  printf 'true\n' >"$state_file"
  touch \
    "$tmpdir/dist/get-bashed-9.9.20-unix.tar.gz" \
    "$tmpdir/dist/get-bashed-9.9.20-windows.zip" \
    "$tmpdir/dist/checksums.txt"

  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
state_file="$state_file"
log="$log"
printf '%s\n' "\$*" >>"\$log"
if [[ "\$1 \$2" == "auth status" ]]; then
  exit 0
fi
if [[ "\$1 \$2" == "release view" ]]; then
  cat "\$state_file"
  exit 0
fi
if [[ "\$1 \$2" == "release upload" ]]; then
  exit 0
fi
if [[ "\$1 \$2" == "release edit" ]]; then
  printf 'false\n' >"\$state_file"
  exit 0
fi
exit 1
EOF
  chmod +x "$bindir/gh"

  run env PATH="$bindir:$PATH" "$MODERN_BASH" ./scripts/publish_draft_release.sh v9.9.20 "$tmpdir/dist" jbcom/get-bashed
  assert_success
  assert_output --partial "published release v9.9.20"

  run grep -F 'release upload v9.9.20' "$log"
  assert_success

  run grep -F 'release edit v9.9.20 --repo jbcom/get-bashed --draft=false' "$log"
  assert_success

  rm -rf "$tmpdir"
}

@test "release validation exercises docs installer and generates package manifests" {
  tmpdir="$(mktemp -d)"

  "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.10 "$tmpdir"

  "$MODERN_BASH" ./scripts/release_validate.sh 9.9.10 "$tmpdir"

  assert_file_exist "$tmpdir/checksums.txt"
  assert_file_exist "$tmpdir/pkg/get-bashed.rb"
  assert_file_exist "$tmpdir/pkg/get-bashed.json"
  assert_file_exist "$tmpdir/pkg/get-bashed.nuspec"
  assert_file_exist "$tmpdir/pkg/chocolateyInstall.ps1"
  assert_file_exist "$tmpdir/pkg/VERIFICATION.txt"

  run grep -F 'stage_dir = Dir["get-bashed-*"].find { |path| File.directory?(path) }' "$tmpdir/pkg/get-bashed.rb"
  assert_success

  run grep -F '#!/bin/sh' "$tmpdir/pkg/get-bashed.rb"
  assert_success

  rm -rf "$tmpdir"
}

@test "docs-site installer accepts bare release versions against a local release mirror" {
  tmpdir="$(mktemp -d)"
  mkdir -p "$tmpdir/home"
  port="$(pick_port)"

  "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.11 "$tmpdir"
  cat "$tmpdir/get-bashed-9.9.11-unix.tar.gz.sha256" "$tmpdir/get-bashed-9.9.11-windows.zip.sha256" >"$tmpdir/checksums.txt"

  python3 -m http.server "$port" --directory "$tmpdir" >"$tmpdir/server.log" 2>&1 &
  server_pid=$!
  wait_for_http "http://127.0.0.1:${port}/checksums.txt"
  wait_for_http "http://127.0.0.1:${port}/get-bashed-9.9.11-unix.tar.gz"

  run env \
    HOME="$tmpdir/home" \
    GET_BASHED_RELEASE_BASE_URL="http://127.0.0.1:${port}" \
    GET_BASHED_RELEASE_CHECKSUMS_URL="http://127.0.0.1:${port}/checksums.txt" \
    sh ./docs/public/install.sh --version 9.9.11 --auto --profiles minimal --prefix "$tmpdir/home/.get-bashed"
  assert_success

  assert_file_exist "$tmpdir/home/.get-bashed/get-bashedrc.sh"

  kill "$server_pid" 2>/dev/null || true
  rm -rf "$tmpdir"
}

@test "docs-site installer can use the supported wget fallback against a local release mirror" {
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$tmpdir/home" "$bindir"
  port="$(pick_port)"

  "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.16 "$tmpdir"
  cat "$tmpdir/get-bashed-9.9.16-unix.tar.gz.sha256" "$tmpdir/get-bashed-9.9.16-windows.zip.sha256" >"$tmpdir/checksums.txt"

  python3 -m http.server "$port" --directory "$tmpdir" >"$tmpdir/server.log" 2>&1 &
  server_pid=$!
  wait_for_http "http://127.0.0.1:${port}/checksums.txt"
  wait_for_http "http://127.0.0.1:${port}/get-bashed-9.9.16-unix.tar.gz"

  cat >"$bindir/wget" <<'EOF'
#!/bin/sh
set -eu

if [ "$#" -eq 2 ] && [ "$1" = "-qO-" ]; then
  exec curl -fsSL "$2"
fi

if [ "$#" -eq 3 ] && [ "$1" = "-qO" ]; then
  exec curl -fsSL -o "$2" "$3"
fi

echo "unsupported fake wget arguments: $*" >&2
exit 1
EOF
  chmod +x "$bindir/wget"

  env \
    HOME="$tmpdir/home" \
    PATH="$bindir:$PATH" \
    GET_BASHED_DOWNLOAD_TOOL="wget" \
    GET_BASHED_RELEASE_BASE_URL="http://127.0.0.1:${port}" \
    GET_BASHED_RELEASE_CHECKSUMS_URL="http://127.0.0.1:${port}/checksums.txt" \
    sh ./docs/public/install.sh --version 9.9.16 --auto --profiles minimal --prefix "$tmpdir/home/.get-bashed"

  assert_file_exist "$tmpdir/home/.get-bashed/get-bashedrc.sh"

  kill "$server_pid" 2>/dev/null || true
  rm -rf "$tmpdir"
}

@test "publish_pkg_pr can stage pkgs changes into a local target repo and call gh" {
  tmpdir="$(mktemp -d)"
  remote="$tmpdir/pkgs.git"
  worktree="$tmpdir/worktree"
  manifests="$tmpdir/manifests"
  bindir="$tmpdir/bin"
  log="$tmpdir/gh.log"

  git init --bare --initial-branch=main "$remote" >/dev/null
  git clone "$remote" "$worktree" >/dev/null
  (
    cd "$worktree"
    git config user.name Test
    git config user.email test@example.com
    touch .keep
    git add .keep
    git commit -m "init" >/dev/null
    git push origin main >/dev/null
  )

  "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.12 "$tmpdir"
  cat "$tmpdir/get-bashed-9.9.12-unix.tar.gz.sha256" "$tmpdir/get-bashed-9.9.12-windows.zip.sha256" >"$tmpdir/checksums.txt"
  "$MODERN_BASH" ./scripts/generate_pkg_manifests.sh 9.9.12 "$tmpdir/checksums.txt" "$manifests"

  mkdir -p "$bindir"
  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$log"
if [[ "\$1 \$2" == "pr create" ]]; then
  printf 'https://example.test/pr/1\n'
fi
EOF
  chmod +x "$bindir/gh"

  run env \
    GH_TOKEN=fake-token \
    TARGET_REPO=jbcom/pkgs \
    TARGET_REPO_URL="$remote" \
    PATH="$bindir:$PATH" \
    "$MODERN_BASH" ./scripts/publish_pkg_pr.sh 9.9.12 "$manifests"
  assert_success

  run git ls-remote --heads "$remote" "refs/heads/get-bashed/bump-9.9.12"
  assert_success
  assert_output --partial "get-bashed/bump-9.9.12"

  checkout="$tmpdir/checkout"
  git clone --branch get-bashed/bump-9.9.12 "$remote" "$checkout" >/dev/null
  assert_file_exist "$checkout/Formula/get-bashed.rb"
  assert_file_exist "$checkout/bucket/get-bashed.json"
  assert_file_exist "$checkout/choco/get-bashed/get-bashed.nuspec"
  assert_file_exist "$checkout/choco/get-bashed/tools/chocolateyInstall.ps1"
  assert_file_exist "$checkout/choco/get-bashed/tools/VERIFICATION.txt"
  assert_file_exist "$log"

  run grep -F 'pr create --repo jbcom/pkgs --base main --head get-bashed/bump-9.9.12' "$log"
  assert_success

  run grep -F 'pr merge --repo jbcom/pkgs --auto --squash https://example.test/pr/1' "$log"
  assert_success

  rm -rf "$tmpdir"
}

@test "publish_pkg_pr uses gh repo clone when a direct target repo url is not provided" {
  tmpdir="$(mktemp -d)"
  remote="$tmpdir/pkgs.git"
  worktree="$tmpdir/worktree"
  manifests="$tmpdir/manifests"
  bindir="$tmpdir/bin"
  log="$tmpdir/gh.log"

  git init --bare --initial-branch=main "$remote" >/dev/null
  git clone "$remote" "$worktree" >/dev/null
  (
    cd "$worktree"
    git config user.name Test
    git config user.email test@example.com
    touch .keep
    git add .keep
    git commit -m "init" >/dev/null
    git push origin main >/dev/null
  )

  "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.17 "$tmpdir"
  cat "$tmpdir/get-bashed-9.9.17-unix.tar.gz.sha256" "$tmpdir/get-bashed-9.9.17-windows.zip.sha256" >"$tmpdir/checksums.txt"
  "$MODERN_BASH" ./scripts/generate_pkg_manifests.sh 9.9.17 "$tmpdir/checksums.txt" "$manifests"

  mkdir -p "$bindir"
  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$log"
if [[ "\$1 \$2" == "repo clone" ]]; then
  git clone "$remote" "\$4" >/dev/null
  exit 0
fi
if [[ "\$1 \$2" == "pr create" ]]; then
  printf 'https://example.test/pr/17\n'
  exit 0
fi
EOF
  chmod +x "$bindir/gh"

  run env \
    GH_TOKEN=fake-token \
    TARGET_REPO=jbcom/pkgs \
    PATH="$bindir:$PATH" \
    "$MODERN_BASH" ./scripts/publish_pkg_pr.sh 9.9.17 "$manifests"
  assert_success

  run grep -F 'repo clone jbcom/pkgs' "$log"
  assert_success

  rm -rf "$tmpdir"
}

@test "publish_pkg_pr accepts a downloaded artifact layout with nested pkg directory" {
  tmpdir="$(mktemp -d)"
  remote="$tmpdir/pkgs.git"
  worktree="$tmpdir/worktree"
  manifests="$tmpdir/artifact/pkg"
  bindir="$tmpdir/bin"
  log="$tmpdir/gh.log"

  git init --bare --initial-branch=main "$remote" >/dev/null
  git clone "$remote" "$worktree" >/dev/null
  (
    cd "$worktree"
    git config user.name Test
    git config user.email test@example.com
    touch .keep
    git add .keep
    git commit -m "init" >/dev/null
    git push origin main >/dev/null
  )

  "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.14 "$tmpdir"
  cat "$tmpdir/get-bashed-9.9.14-unix.tar.gz.sha256" "$tmpdir/get-bashed-9.9.14-windows.zip.sha256" >"$tmpdir/checksums.txt"
  mkdir -p "$manifests"
  "$MODERN_BASH" ./scripts/generate_pkg_manifests.sh 9.9.14 "$tmpdir/checksums.txt" "$manifests"

  mkdir -p "$bindir"
  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$log"
if [[ "\$1 \$2" == "pr create" ]]; then
  printf 'https://example.test/pr/2\n'
fi
EOF
  chmod +x "$bindir/gh"

  run env \
    GH_TOKEN=fake-token \
    TARGET_REPO=jbcom/pkgs \
    TARGET_REPO_URL="$remote" \
    PATH="$bindir:$PATH" \
    "$MODERN_BASH" ./scripts/publish_pkg_pr.sh 9.9.14 "$tmpdir/artifact"
  assert_success

  run git ls-remote --heads "$remote" "refs/heads/get-bashed/bump-9.9.14"
  assert_success
  assert_output --partial "get-bashed/bump-9.9.14"

  run grep -F 'pr create --repo jbcom/pkgs --base main --head get-bashed/bump-9.9.14' "$log"
  assert_success

  rm -rf "$tmpdir"
}

@test "publish_pkg_pr reuses an existing branch and open pr on rerun" {
  tmpdir="$(mktemp -d)"
  remote="$tmpdir/pkgs.git"
  worktree="$tmpdir/worktree"
  manifests="$tmpdir/manifests"
  bindir="$tmpdir/bin"
  log="$tmpdir/gh.log"

  git init --bare --initial-branch=main "$remote" >/dev/null
  git clone "$remote" "$worktree" >/dev/null
  (
    cd "$worktree"
    git config user.name Test
    git config user.email test@example.com
    touch .keep
    git add .keep
    git commit -m "init" >/dev/null
    git push origin main >/dev/null
  )

  "$MODERN_BASH" ./scripts/build_release_artifact.sh 9.9.15 "$tmpdir"
  cat "$tmpdir/get-bashed-9.9.15-unix.tar.gz.sha256" "$tmpdir/get-bashed-9.9.15-windows.zip.sha256" >"$tmpdir/checksums.txt"
  "$MODERN_BASH" ./scripts/generate_pkg_manifests.sh 9.9.15 "$tmpdir/checksums.txt" "$manifests"

  mkdir -p "$bindir"
  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$log"
if [[ "\$1 \$2" == "pr list" ]]; then
  if [[ "\${EXISTING_PR:-0}" == "1" ]]; then
    printf 'https://example.test/pr/3\n'
  fi
  exit 0
fi
if [[ "\$1 \$2" == "pr create" ]]; then
  printf 'https://example.test/pr/3\n'
  exit 0
fi
EOF
  chmod +x "$bindir/gh"

  run env \
    GH_TOKEN=fake-token \
    TARGET_REPO=jbcom/pkgs \
    TARGET_REPO_URL="$remote" \
    PATH="$bindir:$PATH" \
    EXISTING_PR=0 \
    "$MODERN_BASH" ./scripts/publish_pkg_pr.sh 9.9.15 "$manifests"
  assert_success

  run env \
    GH_TOKEN=fake-token \
    TARGET_REPO=jbcom/pkgs \
    TARGET_REPO_URL="$remote" \
    PATH="$bindir:$PATH" \
    EXISTING_PR=1 \
    "$MODERN_BASH" ./scripts/publish_pkg_pr.sh 9.9.15 "$manifests"
  assert_success

  run grep -F 'pr list --repo jbcom/pkgs --head get-bashed/bump-9.9.15 --state open --json url --jq .[0].url // ""' "$log"
  assert_success

  create_count="$(grep -c '^pr create ' "$log" || true)"
  [ "$create_count" -eq 1 ]

  merge_count="$(grep -c '^pr merge --repo jbcom/pkgs --auto --squash https://example.test/pr/3$' "$log" || true)"
  [ "$merge_count" -eq 2 ]

  rm -rf "$tmpdir"
}

@test "publish_pkg_pr fails cleanly when GH_TOKEN is missing" {
  tmpdir="$(mktemp -d)"
  manifests="$tmpdir/manifests"
  mkdir -p "$manifests"
  touch "$manifests/get-bashed.rb" "$manifests/get-bashed.json" \
    "$manifests/get-bashed.nuspec" "$manifests/chocolateyInstall.ps1" "$manifests/VERIFICATION.txt"

  run env -u GH_TOKEN "$MODERN_BASH" ./scripts/publish_pkg_pr.sh 9.9.13 "$manifests"
  assert_failure
  assert_output --partial "GH_TOKEN is required"

  rm -rf "$tmpdir"
}
