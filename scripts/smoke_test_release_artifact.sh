#!/usr/bin/env bash

set -euo pipefail

VERSION_RAW="${1:?version required}"
ARCHIVE_PATH="${2:?archive path required}"
VERSION="${VERSION_RAW#v}"
PYTHON_BIN="${PYTHON:-$(command -v python3 || command -v python || true)}"
TMPDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

extract_zip() {
  if [ -z "$PYTHON_BIN" ]; then
    echo "python3 or python is required to unpack zip archives" >&2
    exit 1
  fi

  "$PYTHON_BIN" - "$ARCHIVE_PATH" "$TMPDIR" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import sys

archive = Path(sys.argv[1])
destination = Path(sys.argv[2])

with ZipFile(archive) as bundle:
    bundle.extractall(destination)
PY
}

case "$(basename "$ARCHIVE_PATH")" in
  "get-bashed-${VERSION}-unix.tar.gz")
    tar -xzf "$ARCHIVE_PATH" -C "$TMPDIR"
    stage_dir="$TMPDIR/get-bashed-${VERSION}-unix"
    test -f "$stage_dir/install.sh"
    test -f "$stage_dir/install.bash"
    test -x "$stage_dir/get-bashed"

    test_home="$TMPDIR/home"
    mkdir -p "$test_home"
    HOME="$test_home" "$stage_dir/get-bashed" --auto --profiles minimal --prefix "$test_home/.get-bashed"

    test -f "$test_home/.get-bashed/get-bashedrc.sh"
    test -d "$test_home/.get-bashed/bashrc.d"
    ;;
  "get-bashed-${VERSION}-windows.zip")
    extract_zip
    test -f "$TMPDIR/install.sh"
    test -f "$TMPDIR/install.bash"
    test -f "$TMPDIR/get-bashed.cmd"
    test -f "$TMPDIR/get-bashed.ps1"
    test -d "$TMPDIR/bashrc.d"
    grep -F 'wsl.exe' "$TMPDIR/get-bashed.ps1" >/dev/null
    grep -F 'bash.exe' "$TMPDIR/get-bashed.ps1" >/dev/null
    grep -F 'powershell -NoProfile' "$TMPDIR/get-bashed.cmd" >/dev/null
    ;;
  *)
    echo "unsupported archive path: $ARCHIVE_PATH" >&2
    exit 64
    ;;
esac
