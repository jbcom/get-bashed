#!/usr/bin/env bats

load test_helper

sha256_of() {
  python3 - "$1" <<'PY'
from hashlib import sha256
from pathlib import Path
import sys

print(sha256(Path(sys.argv[1]).read_bytes()).hexdigest())
PY
}

@test "install.sh ignores PATH bash 3.x when a modern absolute bash is available" {
  [[ -n "$MODERN_BASH" ]] || skip "No Bash 4+ candidate on this platform"

  TMPDIR="$(mktemp -d)"
  FAKEBIN="$TMPDIR/bin"
  MARKER="$TMPDIR/path-bash-used"
  mkdir -p "$FAKEBIN"

  cat > "$FAKEBIN/bash" <<EOF
#!/bin/sh
if [ "\$1" = "-c" ]; then
  printf '3'
  exit 0
fi
echo used > "$MARKER"
exit 99
EOF
  chmod +x "$FAKEBIN/bash"

  run env PATH="$FAKEBIN:/usr/bin:/bin" ./install.sh --help
  assert_success
  assert_file_not_exist "$MARKER"
}

@test "install.sh bootstraps Homebrew before installing bash when only an old bash is available" {
  [[ -n "$MODERN_BASH" ]] || skip "No Bash 4+ candidate on this platform"

  TMPDIR="$(mktemp -d)"
  FAKEBIN="$TMPDIR/bin"
  LOG="$TMPDIR/bootstrap.log"
  INSTALLER_PAYLOAD="$TMPDIR/homebrew-install.sh"
  mkdir -p "$FAKEBIN"

  cat > "$FAKEBIN/bash" <<'EOF'
#!/bin/sh
if [ "$1" = "-c" ]; then
  printf '3'
  exit 0
fi
exit 99
EOF
  chmod +x "$FAKEBIN/bash"

  cat > "$INSTALLER_PAYLOAD" <<EOF
#!/bin/sh
cat > "$FAKEBIN/brew" <<'BREW'
#!/bin/sh
printf '%s\n' "\$*" >> "$LOG"
if [ "\$1" = "install" ] && [ "\$2" = "bash" ]; then
  cat > "$FAKEBIN/bash" <<'MODERN'
#!/bin/sh
if [ "\$1" = "-c" ]; then
  printf '5'
  exit 0
fi
exec "$MODERN_BASH" "\$@"
MODERN
  chmod +x "$FAKEBIN/bash"
  exit 0
fi
exit 1
BREW
chmod +x "$FAKEBIN/brew"
EOF
  chmod +x "$INSTALLER_PAYLOAD"
  BREW_SHA="$(sha256_of "$INSTALLER_PAYLOAD")"

  cat > "$FAKEBIN/curl" <<EOF
#!/bin/sh
out=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o)
      shift
      out="\$1"
      ;;
  esac
  shift
done
cp "$INSTALLER_PAYLOAD" "\$out"
EOF
  chmod +x "$FAKEBIN/curl"

  run env GET_BASHED_BOOTSTRAP_BASH_CANDIDATES="$FAKEBIN/bash" GET_BASHED_BOOTSTRAP_BREW_CANDIDATES="/nonexistent" GET_BASHED_BOOTSTRAP_BREW_SHA256="$BREW_SHA" PATH="$FAKEBIN:/usr/bin:/bin" ./install.sh --help
  assert_success

  run cat "$LOG"
  assert_output "install bash"
}

@test "install.sh ignores package-manager stdout while resolving the bootstrap bash path" {
  [[ -n "$MODERN_BASH" ]] || skip "No Bash 4+ candidate on this platform"

  TMPDIR="$(mktemp -d)"
  FAKEBIN="$TMPDIR/bin"
  INSTALLER_PAYLOAD="$TMPDIR/homebrew-install.sh"
  MARKER="$TMPDIR/install-bash-ran"
  LOG="$TMPDIR/bootstrap.log"
  mkdir -p "$FAKEBIN"

  cat > "$FAKEBIN/bash" <<'EOF'
#!/bin/sh
if [ "$1" = "-c" ]; then
  printf '3'
  exit 0
fi
exit 99
EOF
  chmod +x "$FAKEBIN/bash"

  cat > "$INSTALLER_PAYLOAD" <<EOF
#!/bin/sh
cat > "$FAKEBIN/brew" <<'BREW'
#!/bin/sh
printf 'BREW STDOUT NOISE\n'
printf '%s\n' "\$*" >> "$LOG"
if [ "\$1" = "install" ] && [ "\$2" = "bash" ]; then
  cat > "$FAKEBIN/bash" <<'MODERN'
#!/bin/sh
if [ "\$1" = "-c" ]; then
  printf '5'
  exit 0
fi
printf 'repo bootstrap ok\n' > "$MARKER"
exec "$MODERN_BASH" "\$@"
MODERN
  chmod +x "$FAKEBIN/bash"
  exit 0
fi
exit 1
BREW
chmod +x "$FAKEBIN/brew"
EOF
  chmod +x "$INSTALLER_PAYLOAD"
  BREW_SHA="$(sha256_of "$INSTALLER_PAYLOAD")"

  cat > "$FAKEBIN/curl" <<EOF
#!/bin/sh
out=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o)
      shift
      out="\$1"
      ;;
  esac
  shift
done
cp "$INSTALLER_PAYLOAD" "\$out"
EOF
  chmod +x "$FAKEBIN/curl"

  run env GET_BASHED_BOOTSTRAP_BASH_CANDIDATES="$FAKEBIN/bash" GET_BASHED_BOOTSTRAP_BREW_CANDIDATES="/nonexistent" GET_BASHED_BOOTSTRAP_BREW_SHA256="$BREW_SHA" PATH="$FAKEBIN:/usr/bin:/bin" ./install.sh --help
  assert_success
  assert_file_exist "$MARKER"

  run cat "$LOG"
  assert_output "install bash"
}

@test "standalone install.sh fetches the repo tree before execing install.bash" {
  [[ -n "$MODERN_BASH" ]] || skip "No Bash 4+ candidate on this platform"

  TMPDIR="$(mktemp -d)"
  STANDALONE="$TMPDIR/standalone"
  FAKEBIN="$TMPDIR/bin"
  ARCHIVE_ROOT="$TMPDIR/archive/get-bashed-main"
  ARCHIVE="$TMPDIR/get-bashed-main.tar.gz"
  MARKER="$TMPDIR/install-bash-ran"
  mkdir -p "$STANDALONE" "$FAKEBIN" "$ARCHIVE_ROOT/installers"

  cp ./install.sh "$STANDALONE/install.sh"
  chmod +x "$STANDALONE/install.sh"

  cat > "$ARCHIVE_ROOT/install.bash" <<EOF
#!/usr/bin/env bash
printf '%s\n' "repo bootstrap ok" > "$MARKER"
EOF
  chmod +x "$ARCHIVE_ROOT/install.bash"
  : > "$ARCHIVE_ROOT/installers/_helpers.sh"

  tar -czf "$ARCHIVE" -C "$TMPDIR/archive" get-bashed-main
  ARCHIVE_SHA="$(sha256_of "$ARCHIVE")"

  cat > "$FAKEBIN/bash" <<EOF
#!/bin/sh
if [ "\$1" = "-c" ]; then
  printf '5'
  exit 0
fi
exec "$MODERN_BASH" "\$@"
EOF
  chmod +x "$FAKEBIN/bash"

  cat > "$FAKEBIN/curl" <<EOF
#!/bin/sh
out=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o)
      shift
      out="\$1"
      ;;
  esac
  shift
done
cp "$ARCHIVE" "\$out"
EOF
  chmod +x "$FAKEBIN/curl"

  run env GET_BASHED_BOOTSTRAP_REPO_ARCHIVE_SHA256="$ARCHIVE_SHA" PATH="$FAKEBIN:/usr/bin:/bin" "$STANDALONE/install.sh"
  assert_success
  assert_file_exist "$MARKER"
  run cat "$MARKER"
  assert_output "repo bootstrap ok"
}

@test "standalone install.sh rejects bootstrap archives whose checksum does not match" {
  [[ -n "$MODERN_BASH" ]] || skip "No Bash 4+ candidate on this platform"

  TMPDIR="$(mktemp -d)"
  STANDALONE="$TMPDIR/standalone"
  FAKEBIN="$TMPDIR/bin"
  ARCHIVE_ROOT="$TMPDIR/archive/get-bashed-main"
  ARCHIVE="$TMPDIR/get-bashed-main.tar.gz"
  mkdir -p "$STANDALONE" "$FAKEBIN" "$ARCHIVE_ROOT/installers"

  cp ./install.sh "$STANDALONE/install.sh"
  chmod +x "$STANDALONE/install.sh"

  cat > "$ARCHIVE_ROOT/install.bash" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$ARCHIVE_ROOT/install.bash"
  : > "$ARCHIVE_ROOT/installers/_helpers.sh"

  tar -czf "$ARCHIVE" -C "$TMPDIR/archive" get-bashed-main

  cat > "$FAKEBIN/bash" <<EOF
#!/bin/sh
if [ "\$1" = "-c" ]; then
  printf '5'
  exit 0
fi
exec "$MODERN_BASH" "\$@"
EOF
  chmod +x "$FAKEBIN/bash"

  cat > "$FAKEBIN/curl" <<EOF
#!/bin/sh
out=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o)
      shift
      out="\$1"
      ;;
  esac
  shift
done
cp "$ARCHIVE" "\$out"
EOF
  chmod +x "$FAKEBIN/curl"

  run env GET_BASHED_BOOTSTRAP_REPO_ARCHIVE_SHA256="deadbeef" PATH="$FAKEBIN:/usr/bin:/bin" "$STANDALONE/install.sh"
  assert_failure
  assert_output --partial "checksum verification failed"
}
