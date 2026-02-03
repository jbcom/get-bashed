#!/usr/bin/env bash
# @file gen-docs
# @brief Generate documentation for get-bashed.
# @description
#     Uses shdoc to generate markdown docs from shell scripts.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v shdoc >/dev/null 2>&1 || {
  echo "shdoc is required. Install with: ./install.sh --install shdoc" >&2
  exit 1
}

shdoc < "$ROOT_DIR/install.sh" > "$ROOT_DIR/docs/INSTALLER.md"
shdoc < "$ROOT_DIR/installers/_helpers.sh" > "$ROOT_DIR/docs/INSTALLERS_HELPERS.md"
shdoc < "$ROOT_DIR/installers/tools.sh" > "$ROOT_DIR/docs/INSTALLERS.md"

# Combine all runtime modules
TMP_MODULES="$(mktemp)"
for f in "$ROOT_DIR/bashrc.d"/*.sh; do
  {
    echo ""
    cat "$f"
    echo ""
    echo "# ----"
    echo ""
  } >> "$TMP_MODULES"
done
shdoc < "$TMP_MODULES" > "$ROOT_DIR/docs/MODULES.md"
rm -f "$TMP_MODULES"

# Generate index
{
  echo "# get-bashed Docs"
  echo ""
  echo "Generated docs:"
  for f in "$ROOT_DIR/docs"/*.md; do
    base="$(basename "$f")"
    [[ "$base" == "index.md" ]] && continue
    echo "- [$base]($base)"
  done
} > "$ROOT_DIR/docs/INDEX.md"

echo "Docs generated under docs/"
