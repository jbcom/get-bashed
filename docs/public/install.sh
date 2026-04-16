#!/bin/sh
# get-bashed docs-site installer.
#
# Usage:
#   curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh
#   curl -fsSL https://jbcom.github.io/get-bashed/install.sh | sh -s -- --version v0.1.0 --profiles dev

set -eu

REPO="jbcom/get-bashed"
VERSION="latest"
DOWNLOAD_BASE_URL=""
CHECKSUMS_URL=""
TAG=""
DOWNLOADER=""

usage() {
  cat <<'EOF'
Usage:
  install.sh [--version TAG] [installer args...]

Examples:
  install.sh
  install.sh --version v0.1.0 --profiles dev --link-dotfiles
EOF
}

checksum_check() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c -
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c -
    return
  fi
  echo "install.sh: no SHA-256 checksum tool found (need sha256sum or shasum)" >&2
  exit 1
}

resolve_downloader() {
  case "${GET_BASHED_DOWNLOAD_TOOL:-auto}" in
    auto)
      if command -v curl >/dev/null 2>&1; then
        printf '%s\n' "curl"
        return
      fi
      if command -v wget >/dev/null 2>&1; then
        printf '%s\n' "wget"
        return
      fi
      ;;
    curl|wget)
      if command -v "${GET_BASHED_DOWNLOAD_TOOL}" >/dev/null 2>&1; then
        printf '%s\n' "${GET_BASHED_DOWNLOAD_TOOL}"
        return
      fi
      echo "install.sh: requested downloader '${GET_BASHED_DOWNLOAD_TOOL}' is not available" >&2
      exit 1
      ;;
    *)
      echo "install.sh: unsupported GET_BASHED_DOWNLOAD_TOOL '${GET_BASHED_DOWNLOAD_TOOL}' (expected auto, curl, or wget)" >&2
      exit 1
      ;;
  esac

  printf '%s\n' ""
}

download() {
  case "$DOWNLOADER" in
    curl)
      curl -fsSL -o "$2" "$1"
      return
      ;;
    wget)
      wget -qO "$2" "$1"
      return
      ;;
  esac
  echo "install.sh: need curl or wget to download release assets" >&2
  exit 1
}

download_text() {
  case "$DOWNLOADER" in
    curl)
      curl -fsSL "$1"
      return
      ;;
    wget)
      wget -qO- "$1"
      return
      ;;
  esac
  echo "install.sh: need curl or wget to query release metadata" >&2
  exit 1
}

detect_platform() {
  platform="$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  case "$platform" in
    msys*|mingw*|cygwin*)
      echo "install.sh: Windows shells should use WSL, Scoop, Chocolatey, or the release bundle wrappers" >&2
      exit 1
      ;;
  esac
}

normalize_version() {
  case "$VERSION" in
    latest)
      TAG="latest"
      ;;
    v*)
      TAG="$VERSION"
      VERSION="${VERSION#v}"
      ;;
    *)
      TAG="v$VERSION"
      ;;
  esac
}

resolve_latest_version() {
  TAG="$(
    download_text "${GET_BASHED_RELEASE_METADATA_URL:-https://api.github.com/repos/$REPO/releases/latest}" \
      | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' \
      | head -n 1
  )"

  if [ -z "$TAG" ]; then
    echo "install.sh: could not resolve latest version" >&2
    exit 1
  fi

  VERSION="${TAG#v}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="${2:?missing value for --version}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

detect_platform
DOWNLOADER="$(resolve_downloader)"

if [ "$VERSION" = "latest" ]; then
  resolve_latest_version
else
  normalize_version
fi

ARCHIVE="get-bashed-${VERSION}-unix.tar.gz"

if [ -n "${GET_BASHED_RELEASE_BASE_URL:-}" ]; then
  DOWNLOAD_BASE_URL="${GET_BASHED_RELEASE_BASE_URL}"
else
  DOWNLOAD_BASE_URL="https://github.com/$REPO/releases/download/$TAG"
fi

if [ -n "${GET_BASHED_RELEASE_CHECKSUMS_URL:-}" ]; then
  CHECKSUMS_URL="${GET_BASHED_RELEASE_CHECKSUMS_URL}"
else
  CHECKSUMS_URL="${DOWNLOAD_BASE_URL}/checksums.txt"
fi

TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t get-bashed-release)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT INT TERM

download "${DOWNLOAD_BASE_URL}/${ARCHIVE}" "$TMPDIR/$ARCHIVE" || {
  echo "install.sh: failed to download ${ARCHIVE}" >&2
  exit 1
}

download "$CHECKSUMS_URL" "$TMPDIR/checksums.txt" || {
  echo "install.sh: failed to download checksums.txt" >&2
  exit 1
}

(
  cd "$TMPDIR"
  grep "  ${ARCHIVE}\$" checksums.txt | checksum_check
) || {
  echo "install.sh: checksum verification failed for ${ARCHIVE}" >&2
  exit 1
}

mkdir -p "$TMPDIR/unpack"
tar -xzf "$TMPDIR/$ARCHIVE" -C "$TMPDIR/unpack"

STAGE_DIR="$TMPDIR/unpack/get-bashed-${VERSION}-unix"
if [ ! -f "$STAGE_DIR/install.sh" ]; then
  echo "install.sh: bundled install.sh missing from release archive" >&2
  exit 1
fi

exec sh "$STAGE_DIR/install.sh" "$@"
