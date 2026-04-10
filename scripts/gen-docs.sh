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

shdoc < "$ROOT_DIR/install.bash" > "$ROOT_DIR/docs/INSTALLER.md"
shdoc < "$ROOT_DIR/installers/_helpers.sh" > "$ROOT_DIR/docs/INSTALLERS_HELPERS.md"
shdoc < "$ROOT_DIR/installers/tools.sh" > "$ROOT_DIR/docs/INSTALLERS.md"

fix_toc_anchors() {
  local file="$1" tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  awk '
    function anchorize(text,   t) {
      t = tolower(text)
      gsub(/ /, "-", t)
      gsub(/[^a-z0-9_-]/, "", t)
      return t
    }
    {
      if (match($0, /^\* \[[^]]+\]\(#/)) {
        line = $0
        sub(/^\* \[/, "", line)
        text = line
        sub(/\].*$/, "", text)
        anchor = anchorize(text)
        print "* [" text "](#" anchor ")"
      } else {
        print $0
      }
    }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

ensure_eof() {
  local file="$1"
  python3 - "$file" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
data = path.read_bytes()
if not data.endswith(b"\n"):
    path.write_bytes(data + b"\n")
PY
}

for doc in "$ROOT_DIR/docs/INSTALLER.md" "$ROOT_DIR/docs/INSTALLERS_HELPERS.md" "$ROOT_DIR/docs/INSTALLERS.md"; do
  fix_toc_anchors "$doc"
  ensure_eof "$doc"
done

# Combine all runtime modules
TMP_MODULES="$(mktemp)"
trap 'rm -f "$TMP_MODULES"' EXIT
shopt -s nullglob
for f in "$ROOT_DIR/bashrc.d"/*.sh; do
  {
    echo ""
    cat "$f"
    echo ""
    echo "# ----"
    echo ""
  } >> "$TMP_MODULES"
done
shopt -u nullglob
shdoc < "$TMP_MODULES" > "$ROOT_DIR/docs/MODULES.md"
fix_toc_anchors "$ROOT_DIR/docs/MODULES.md"
ensure_eof "$ROOT_DIR/docs/MODULES.md"

# Note: index.md is maintained manually for Sphinx toctree.
echo "Docs generated under docs/"
