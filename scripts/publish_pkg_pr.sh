#!/usr/bin/env bash

set -euo pipefail

VERSION_RAW="${1:?version required}"
MANIFEST_DIR_INPUT="${2:?manifest directory required}"
VERSION="${VERSION_RAW#v}"
TARGET_REPO="${TARGET_REPO:-jbcom/pkgs}"
TARGET_BASE_BRANCH="${TARGET_BASE_BRANCH:-main}"
GIT_NAME="${GIT_NAME:-jbcom-bot}"
GIT_EMAIL="${GIT_EMAIL:-noreply@jonbogaty.com}"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "GH_TOKEN is required to publish package PRs" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required to publish package PRs" >&2
  exit 1
fi

resolve_manifest_dir() {
  local candidate="$1"
  if [ -f "$candidate/get-bashed.rb" ] && [ -f "$candidate/get-bashed.json" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  if [ -d "$candidate/pkg" ] && [ -f "$candidate/pkg/get-bashed.rb" ] && [ -f "$candidate/pkg/get-bashed.json" ]; then
    printf '%s\n' "$candidate/pkg"
    return 0
  fi
  echo "manifest directory does not contain generated package files: $candidate" >&2
  exit 1
}

MANIFEST_DIR="$(resolve_manifest_dir "$MANIFEST_DIR_INPUT")"

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

if [ -n "${TARGET_REPO_URL:-}" ]; then
  git clone "$TARGET_REPO_URL" "$tmpdir/pkgs"
else
  gh repo clone "$TARGET_REPO" "$tmpdir/pkgs"
fi
cd "$tmpdir/pkgs"

branch="get-bashed/bump-${VERSION}"
git checkout -B "$branch" "origin/${TARGET_BASE_BRANCH}"
mkdir -p Formula bucket choco/get-bashed/tools

cp "$MANIFEST_DIR/get-bashed.rb" Formula/get-bashed.rb
cp "$MANIFEST_DIR/get-bashed.json" bucket/get-bashed.json
cp "$MANIFEST_DIR/get-bashed.nuspec" choco/get-bashed/get-bashed.nuspec
cp "$MANIFEST_DIR/chocolateyInstall.ps1" choco/get-bashed/tools/chocolateyInstall.ps1
cp "$MANIFEST_DIR/VERIFICATION.txt" choco/get-bashed/tools/VERIFICATION.txt

git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"
git add Formula/get-bashed.rb bucket/get-bashed.json choco/get-bashed

if git diff --cached --quiet; then
  echo "No package manifest changes for ${VERSION}"
  exit 0
fi

git commit -m "feat(get-bashed): bump to ${VERSION}"
git push -u origin "$branch" --force-with-lease

pr_url="$(
  gh pr list \
    --repo "$TARGET_REPO" \
    --head "$branch" \
    --state open \
    --json url \
    --jq '.[0].url // ""'
)"

if [ -z "$pr_url" ]; then
  pr_url="$(
    gh pr create \
      --repo "$TARGET_REPO" \
      --base "$TARGET_BASE_BRANCH" \
      --head "$branch" \
      --title "feat(get-bashed): bump to ${VERSION}" \
      --body "Auto-generated from get-bashed release pipeline for v${VERSION}."
  )"
fi

gh pr merge --repo "$TARGET_REPO" --auto --squash "$pr_url"
