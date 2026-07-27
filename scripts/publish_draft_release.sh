#!/usr/bin/env bash

set -euo pipefail

TAG="${1:?release tag required (for example v0.1.0)}"
DIST_DIR="${2:?dist dir required}"
REPO="${3:-jbcom/get-bashed}"
PUBLISH_RELEASE="${4:-${PUBLISH_RELEASE:-true}}"

case "$TAG" in
  v*) VERSION="${TAG#v}" ;;
  *) VERSION="$TAG"; TAG="v$TAG" ;;
esac

UNIX_ARCHIVE="get-bashed-${VERSION}-unix.tar.gz"
WINDOWS_ARCHIVE="get-bashed-${VERSION}-windows.zip"
CHECKSUMS_FILE="checksums.txt"

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "missing release artifact: $path" >&2
    exit 1
  fi
}

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required for draft release publication" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh auth is required for draft release publication" >&2
  exit 1
fi

require_file "$DIST_DIR/$UNIX_ARCHIVE"
require_file "$DIST_DIR/$WINDOWS_ARCHIVE"
require_file "$DIST_DIR/$CHECKSUMS_FILE"

is_draft="$(gh release view "$TAG" --repo "$REPO" --json isDraft --jq '.isDraft')"
if [ "$is_draft" != "true" ]; then
  echo "release ${TAG} in ${REPO} must exist as a draft before assets can be uploaded" >&2
  exit 1
fi

gh release upload "$TAG" \
  "$DIST_DIR/$UNIX_ARCHIVE" \
  "$DIST_DIR/$WINDOWS_ARCHIVE" \
  "$DIST_DIR/$CHECKSUMS_FILE" \
  --repo "$REPO" \
  --clobber

if [ "$PUBLISH_RELEASE" = "true" ]; then
  gh release edit "$TAG" --repo "$REPO" --draft=false >/dev/null
  is_draft="$(gh release view "$TAG" --repo "$REPO" --json isDraft --jq '.isDraft')"
  if [ "$is_draft" != "false" ]; then
    echo "release ${TAG} in ${REPO} did not publish successfully" >&2
    exit 1
  fi
  printf 'published release %s in %s\n' "$TAG" "$REPO"
else
  printf 'uploaded assets to draft release %s in %s\n' "$TAG" "$REPO"
fi
