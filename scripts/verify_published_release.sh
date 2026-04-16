#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:?release tag required (for example v0.1.0)}"
REPO="${2:-jbcom/get-bashed}"
OWNER="${3:-jbcom}"
case "$TAG" in
  v*) VERSION="${TAG#v}" ;;
  *) VERSION="$TAG"; TAG="v$TAG" ;;
esac
UNIX_ARCHIVE="get-bashed-${VERSION}-unix.tar.gz"
WINDOWS_ARCHIVE="get-bashed-${VERSION}-windows.zip"
EXPECTED_ASSETS=("checksums.txt" "$UNIX_ARCHIVE" "$WINDOWS_ARCHIVE")

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required for published release verification" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh auth is required for published release verification" >&2
  exit 1
fi

is_draft="$(gh release view "$TAG" --repo "$REPO" --json isDraft --jq '.isDraft')"
if [ "$is_draft" != "false" ]; then
  printf 'release %s in %s is still a draft\n' "$TAG" "$REPO" >&2
  exit 1
fi

mapfile -t actual_assets < <(
  gh release view "$TAG" --repo "$REPO" --json assets --jq '.assets[].name' | LC_ALL=C sort
)
mapfile -t expected_sorted < <(printf '%s\n' "${EXPECTED_ASSETS[@]}" | LC_ALL=C sort)

if [ "${#actual_assets[@]}" -ne "${#expected_sorted[@]}" ]; then
  printf 'unexpected asset count for %s: expected %d, got %d\n' \
    "$TAG" "${#expected_sorted[@]}" "${#actual_assets[@]}" >&2
  printf 'actual assets:\n%s\n' "$(printf '%s\n' "${actual_assets[@]}")" >&2
  exit 1
fi

for idx in "${!expected_sorted[@]}"; do
  if [ "${expected_sorted[$idx]}" != "${actual_assets[$idx]}" ]; then
    printf 'asset mismatch for %s: expected %s, got %s\n' \
      "$TAG" "${expected_sorted[$idx]}" "${actual_assets[$idx]}" >&2
    exit 1
  fi
done

tmpdir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

gh release download "$TAG" --repo "$REPO" \
  -p "$UNIX_ARCHIVE" \
  -p "$WINDOWS_ARCHIVE" \
  -p "checksums.txt" \
  --dir "$tmpdir"

verify_checksum() {
  local artifact="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$tmpdir"
      grep " ${artifact}\$" checksums.txt | sha256sum -c -
    )
  else
    (
      cd "$tmpdir"
      grep " ${artifact}\$" checksums.txt | shasum -a 256 -c -
    )
  fi
}

verify_checksum "$UNIX_ARCHIVE"
verify_checksum "$WINDOWS_ARCHIVE"

(
  cd "$tmpdir"
  gh attestation verify "$UNIX_ARCHIVE" --owner "$OWNER"
  gh attestation verify "$WINDOWS_ARCHIVE" --owner "$OWNER"
)

bash "$ROOT_DIR/scripts/smoke_test_release_artifact.sh" "$VERSION" "$tmpdir/$UNIX_ARCHIVE"
bash "$ROOT_DIR/scripts/smoke_test_release_artifact.sh" "$VERSION" "$tmpdir/$WINDOWS_ARCHIVE"

printf 'published release verified for %s\n' "$TAG"
