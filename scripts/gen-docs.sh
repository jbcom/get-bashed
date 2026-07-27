#!/usr/bin/env bash
# @file gen-docs
# @brief Generate documentation for get-bashed.
# @description
#     Uses shdoc plus registry metadata to generate installer documentation.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v shdoc >/dev/null 2>&1 || {
  echo "shdoc is required. Install with: ./install.sh --install shdoc" >&2
  exit 1
}

fix_toc_anchors() {
  local file="$1"
  local tmp

  tmp="$(mktemp)"
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
  rm -f "$tmp"
}

ensure_eof() {
  local file="$1"
  local last_char

  [[ -s "$file" ]] || return 0
  last_char="$(tail -c 1 "$file" 2>/dev/null || true)"
  [[ -n "$last_char" ]] && printf '\n' >> "$file"
  return 0
}

generate_shdoc_doc() {
  local output="$1"
  shift
  local tmp

  tmp="$(mktemp)"

  for source_file in "$@"; do
    cat "$source_file" >> "$tmp"
    printf '\n' >> "$tmp"
  done

  shdoc < "$tmp" > "$output"
  rm -f "$tmp"
  fix_toc_anchors "$output"
  ensure_eof "$output"
}

generate_installers_catalog() {
  local output="$ROOT_DIR/docs/INSTALLERS.md"

  (
    # shellcheck disable=SC1091
    source "$ROOT_DIR/installers/_helpers.sh"
    # shellcheck disable=SC1091
    source "$ROOT_DIR/installers/tools.sh"

    markdown_cell() {
      printf '%s' "$1" | sed 's/|/\\|/g'
    }

    printf '# Tool Registry\n\n'
    printf "Generated from \`installers/tools.sh\` and pinned source metadata.\n\n"
    printf '| Tool | Description | Dependencies | Platforms | Methods |\n'
    printf '|---|---|---|---|---|\n'

    for id in "${TOOL_IDS[@]}"; do
      printf "| \`%s\` | %s | %s | %s | %s |\n" \
        "$id" \
        "$(markdown_cell "${TOOL_DESC[$id]}")" \
        "$(markdown_cell "${TOOL_DEPS[$id]:-<none>}")" \
        "$(markdown_cell "${TOOL_PLATFORMS[$id]:-<none>}")" \
        "$(markdown_cell "${TOOL_METHODS[$id]:-<none>}")"
    done
  ) > "$output"

  ensure_eof "$output"
}

generate_shdoc_doc \
  "$ROOT_DIR/docs/INSTALLER.md" \
  "$ROOT_DIR/install.bash" \
  "$ROOT_DIR/installlib/config.sh" \
  "$ROOT_DIR/installlib/resolve.sh" \
  "$ROOT_DIR/installlib/ui.sh" \
  "$ROOT_DIR/installlib/filesystem.sh" \
  "$ROOT_DIR/installlib/managed_files.sh" \
  "$ROOT_DIR/installlib/runtime_files.sh" \
  "$ROOT_DIR/installlib/installers.sh"

generate_shdoc_doc \
  "$ROOT_DIR/docs/INSTALLERS_HELPERS.md" \
  "$ROOT_DIR/installers/_helpers.sh" \
  "$ROOT_DIR/installers/lib/core.sh" \
  "$ROOT_DIR/installers/lib/system.sh" \
  "$ROOT_DIR/installers/lib/packages.sh" \
  "$ROOT_DIR/installers/lib/asdf.sh" \
  "$ROOT_DIR/installers/lib/tool_runner.sh" \
  "$ROOT_DIR/installers/lib/installers.sh" \
  "$ROOT_DIR/installers/lib/languages.sh"

generate_installers_catalog

echo "Docs generated under docs/"
