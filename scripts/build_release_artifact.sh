#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_RAW="${1:?version required}"
OUT_DIR="${2:?output dir required}"
VERSION="${VERSION_RAW#v}"
PYTHON_BIN="${PYTHON:-$(command -v python3 || command -v python || true)}"

UNIX_NAME="get-bashed-${VERSION}-unix"
WINDOWS_NAME="get-bashed-${VERSION}-windows"
UNIX_ARCHIVE="${OUT_DIR}/${UNIX_NAME}.tar.gz"
WINDOWS_ARCHIVE="${OUT_DIR}/${WINDOWS_NAME}.zip"
TMPDIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

if [ -z "$PYTHON_BIN" ]; then
  echo "python3 or python is required to build release archives" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

bundle_paths=(
  install.sh
  install.bash
  bash_aliases
  bash_profile
  bashrc
  gitconfig
  inputrc
  vimrc
  LICENSE
  README.md
  CHANGELOG.md
  TOOLS.md
  SECURITY.md
  bashrc.d
  bin
  installers
  installlib
  profiles
  secrets.d
)

copy_bundle() {
  local destination="$1"
  mkdir -p "$destination"
  (
    cd "$ROOT_DIR"
    tar \
      --exclude='*/__pycache__' \
      --exclude='*.pyc' \
      --exclude='.DS_Store' \
      -cf - "${bundle_paths[@]}"
  ) | (
    cd "$destination"
    tar -xf -
  )
}

write_unix_wrapper() {
  local path="$1"
  cat >"$path" <<'EOF'
#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "$0")" && pwd)"
exec sh "$SCRIPT_DIR/install.sh" "$@"
EOF
  chmod +x "$path"
}

write_windows_wrappers() {
  local root="$1"

  cat >"$root/get-bashed.ps1" <<'EOF'
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installSh = Join-Path $scriptDir 'install.sh'
$forward = @($args)

if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
  $resolved = [System.IO.Path]::GetFullPath($installSh)
  $drive = $resolved.Substring(0, 1).ToLowerInvariant()
  $pathPart = $resolved.Substring(2).Replace('\', '/')
  $wslPath = "/mnt/$drive$pathPart"
  & wsl.exe --exec sh $wslPath @forward
  exit $LASTEXITCODE
}

if (Get-Command bash.exe -ErrorAction SilentlyContinue) {
  $resolved = [System.IO.Path]::GetFullPath($installSh)
  $drive = $resolved.Substring(0, 1).ToLowerInvariant()
  $pathPart = $resolved.Substring(2).Replace('\', '/')
  $msysPath = "/$drive$pathPart"
  & bash.exe -lc 'sh "$0" "$@"' $msysPath @forward
  exit $LASTEXITCODE
}

Write-Error 'get-bashed requires WSL (preferred) or bash.exe from Git Bash on Windows.'
exit 1
EOF

  cat >"$root/get-bashed.cmd" <<'EOF'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0get-bashed.ps1" %*
EOF
}

write_checksums() {
  local artifact="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$(dirname "$artifact")"
      sha256sum "$(basename "$artifact")"
    ) >"${artifact}.sha256"
  else
    (
      cd "$(dirname "$artifact")"
      shasum -a 256 "$(basename "$artifact")"
    ) >"${artifact}.sha256"
  fi
}

unix_stage="${TMPDIR}/${UNIX_NAME}"
windows_stage="${TMPDIR}/windows-root"

copy_bundle "$unix_stage"
copy_bundle "$windows_stage"
write_unix_wrapper "$unix_stage/get-bashed"
write_windows_wrappers "$windows_stage"

tar -C "$TMPDIR" -czf "$UNIX_ARCHIVE" "$UNIX_NAME"

"$PYTHON_BIN" - "$windows_stage" "$WINDOWS_ARCHIVE" <<'PY'
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
import sys

stage = Path(sys.argv[1])
archive = Path(sys.argv[2])

with ZipFile(archive, "w", compression=ZIP_DEFLATED) as bundle:
    for path in sorted(stage.rglob("*")):
        if path.is_file():
            bundle.write(path, path.relative_to(stage))
PY

write_checksums "$UNIX_ARCHIVE"
write_checksums "$WINDOWS_ARCHIVE"
