#!/usr/bin/env bash
# @file package
# @brief Package get-bashed into a tarball.
# @description
#     Produces a versioned tarball for releases.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/dist}"
VERSION="${2:-$(git describe --tags --always --dirty)}"

mkdir -p "$OUT_DIR"
TARBALL="$OUT_DIR/get-bashed-${VERSION}.tar.gz"

tar -czf "$TARBALL" \
  --exclude-vcs \
  --exclude='./dist' \
  --exclude='./tests' \
  --exclude='./.github' \
  -C "$ROOT_DIR" .

echo "$TARBALL"
