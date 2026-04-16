#!/usr/bin/env bash
# @file package
# @brief Compatibility wrapper around the release packager.
# @description
#     Produces the Unix release tarball used by the newer release pipeline.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/dist}"
VERSION_RAW="${2:-$(git describe --tags --always --dirty)}"
VERSION="${VERSION_RAW#v}"

bash "$ROOT_DIR/scripts/build_release_artifact.sh" "$VERSION" "$OUT_DIR" >/dev/null

printf '%s\n' "$OUT_DIR/get-bashed-${VERSION}-unix.tar.gz"
