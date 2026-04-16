#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_RAW="${1:?version required}"
DIST_DIR="${2:?dist dir required}"
VERSION="${VERSION_RAW#v}"
PYTHON_BIN="${PYTHON:-$(command -v python3 || command -v python || true)}"
UNIX_ARCHIVE="get-bashed-${VERSION}-unix.tar.gz"
WINDOWS_ARCHIVE="get-bashed-${VERSION}-windows.zip"

if [ -z "$PYTHON_BIN" ]; then
  echo "python3 or python is required for release validation" >&2
  exit 1
fi

pick_port() {
  "$PYTHON_BIN" - <<'PY'
import socket

sock = socket.socket()
sock.bind(("127.0.0.1", 0))
print(sock.getsockname()[1])
sock.close()
PY
}

wait_for_http() {
  local url="$1"
  for _ in $(seq 1 50); do
    if "$PYTHON_BIN" - "$url" <<'PY' >/dev/null 2>&1
from urllib.request import urlopen
import sys

with urlopen(sys.argv[1], timeout=1):
    pass
PY
    then
      return 0
    fi
    sleep 0.1
  done
  echo "timed out waiting for ${url}" >&2
  exit 1
}

emulate_homebrew_install() {
  local source_root="$1"
  local version="$2"
  local prefix_root="$3"
  local stage_dir="$source_root/get-bashed-${version}-unix"
  local libexec_dir="$prefix_root/libexec"
  local bin_dir="$prefix_root/bin"

  test -d "$stage_dir"
  mkdir -p "$libexec_dir" "$bin_dir"
  cp -R "$stage_dir"/. "$libexec_dir"/

  cat >"$bin_dir/get-bashed" <<EOF
#!/bin/sh
exec "$libexec_dir/install.sh" "\$@"
EOF
  chmod +x "$bin_dir/get-bashed"
}

extract_zip() {
  local archive="$1"
  local destination="$2"
  "$PYTHON_BIN" - "$archive" "$destination" <<'PY'
from pathlib import Path
from zipfile import ZipFile
import sys

archive = Path(sys.argv[1])
destination = Path(sys.argv[2])

with ZipFile(archive) as bundle:
    bundle.extractall(destination)
PY
}

validate_windows_package_consumers() {
  local archive="$1"
  local scoop_manifest="$2"
  local choco_script="$3"
  local destination="$4"

  extract_zip "$archive" "$destination"

  "$PYTHON_BIN" - "$scoop_manifest" "$destination" <<'PY'
from pathlib import Path
import json
import sys

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = Path(sys.argv[2])
bin_name = manifest["bin"]

if not (root / bin_name).is_file():
    raise SystemExit(f"Scoop bin target missing from zip: {bin_name}")
PY

  grep -F "Install-BinFile -Name 'get-bashed' -Path (Join-Path \$toolsDir 'get-bashed.cmd')" "$choco_script" >/dev/null
  test -f "$destination/get-bashed.cmd"
  test -f "$destination/get-bashed.ps1"
}

verify_checksum() {
  local archive="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$DIST_DIR"
      grep " ${archive}\$" checksums.txt | sha256sum -c -
    )
  else
    (
      cd "$DIST_DIR"
      grep " ${archive}\$" checksums.txt | shasum -a 256 -c -
    )
  fi
}

for archive in "$UNIX_ARCHIVE" "$WINDOWS_ARCHIVE"; do
  test -f "$DIST_DIR/$archive"
  test -f "$DIST_DIR/$archive.sha256"
done

cat "$DIST_DIR/$UNIX_ARCHIVE.sha256" "$DIST_DIR/$WINDOWS_ARCHIVE.sha256" >"$DIST_DIR/checksums.txt"

verify_checksum "$UNIX_ARCHIVE"
verify_checksum "$WINDOWS_ARCHIVE"

bash "$ROOT_DIR/scripts/smoke_test_release_artifact.sh" "$VERSION" "$DIST_DIR/$UNIX_ARCHIVE"
bash "$ROOT_DIR/scripts/smoke_test_release_artifact.sh" "$VERSION" "$DIST_DIR/$WINDOWS_ARCHIVE"

pkg_dir="$DIST_DIR/pkg"
rm -rf "$pkg_dir"
bash "$ROOT_DIR/scripts/generate_pkg_manifests.sh" "$VERSION" "$DIST_DIR/checksums.txt" "$pkg_dir"

test -f "$pkg_dir/get-bashed.rb"
test -f "$pkg_dir/get-bashed.json"
test -f "$pkg_dir/get-bashed.nuspec"
test -f "$pkg_dir/chocolateyInstall.ps1"
test -f "$pkg_dir/VERIFICATION.txt"
ruby -c "$pkg_dir/get-bashed.rb" >/dev/null
"$PYTHON_BIN" -m json.tool "$pkg_dir/get-bashed.json" >/dev/null
"$PYTHON_BIN" - <<'PY' "$pkg_dir/get-bashed.nuspec"
import sys
import xml.etree.ElementTree as ET

ET.parse(sys.argv[1])
PY

install_home="$(mktemp -d)"
latest_home="$(mktemp -d)"
brew_stage="$(mktemp -d)"
brew_prefix="$(mktemp -d)"
windows_stage="$(mktemp -d)"
server_log="$DIST_DIR/http-server.log"
port="$(pick_port)"
cleanup() {
  rm -rf "$install_home"
  rm -rf "$latest_home"
  rm -rf "$brew_stage"
  rm -rf "$brew_prefix"
  rm -rf "$windows_stage"
  kill "${server_pid:-0}" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$install_home/home"
mkdir -p "$latest_home/home"
cat >"$DIST_DIR/latest.json" <<EOF
{"tag_name":"v${VERSION}"}
EOF

"$PYTHON_BIN" -m http.server "$port" --directory "$DIST_DIR" >"$server_log" 2>&1 &
server_pid=$!
wait_for_http "http://127.0.0.1:${port}/checksums.txt"
wait_for_http "http://127.0.0.1:${port}/${UNIX_ARCHIVE}"
wait_for_http "http://127.0.0.1:${port}/latest.json"

HOME="$install_home/home" \
GET_BASHED_RELEASE_BASE_URL="http://127.0.0.1:${port}" \
GET_BASHED_RELEASE_CHECKSUMS_URL="http://127.0.0.1:${port}/checksums.txt" \
  sh "$ROOT_DIR/docs/public/install.sh" --version "v${VERSION}" --auto --profiles minimal --prefix "$install_home/home/.get-bashed"

test -f "$install_home/home/.get-bashed/get-bashedrc.sh"

HOME="$latest_home/home" \
GET_BASHED_RELEASE_METADATA_URL="http://127.0.0.1:${port}/latest.json" \
GET_BASHED_RELEASE_BASE_URL="http://127.0.0.1:${port}" \
GET_BASHED_RELEASE_CHECKSUMS_URL="http://127.0.0.1:${port}/checksums.txt" \
  sh "$ROOT_DIR/docs/public/install.sh" --auto --profiles minimal --prefix "$latest_home/home/.get-bashed"

test -f "$latest_home/home/.get-bashed/get-bashedrc.sh"

tar -xzf "$DIST_DIR/$UNIX_ARCHIVE" -C "$brew_stage"
emulate_homebrew_install "$brew_stage" "$VERSION" "$brew_prefix"

HOME="$brew_prefix/home" "$brew_prefix/bin/get-bashed" --auto --profiles minimal --prefix "$brew_prefix/home/.get-bashed"
test -f "$brew_prefix/home/.get-bashed/get-bashedrc.sh"

validate_windows_package_consumers \
  "$DIST_DIR/$WINDOWS_ARCHIVE" \
  "$pkg_dir/get-bashed.json" \
  "$pkg_dir/chocolateyInstall.ps1" \
  "$windows_stage"
