#!/usr/bin/env bats

load test_helper

@test "test-setup realigns an existing helper repo to the pinned sha" {
  TMPDIR="$(mktemp -d)"
  REPO="$TMPDIR/repo"
  DEST="$TMPDIR/lib"
  mkdir -p "$DEST"

  git init "$REPO" >/dev/null
  git -C "$REPO" config user.name "Test User"
  git -C "$REPO" config user.email "test@example.com"

  printf 'first\n' > "$REPO/file.txt"
  git -C "$REPO" add file.txt
  git -C "$REPO" commit -m first >/dev/null
  SHA1="$(git -C "$REPO" rev-parse HEAD)"

  printf 'second\n' > "$REPO/file.txt"
  git -C "$REPO" commit -am second >/dev/null
  SHA2="$(git -C "$REPO" rev-parse HEAD)"

  git clone "$REPO" "$DEST/sample" >/dev/null 2>&1
  git -C "$DEST/sample" checkout "$SHA2" >/dev/null 2>&1

  run env TEST_SETUP_SKIP_MAIN=1 "$MODERN_BASH" -c 'source scripts/test-setup.sh; LIB_DIR="'"$DEST"'"; clone_lib sample "'"$REPO"'" "'"$SHA1"'"'
  assert_success

  run git -C "$DEST/sample" rev-parse HEAD
  assert_output "$SHA1"
}

@test "test-setup waits for an active helper lock instead of clobbering concurrent setup" {
  TMPDIR="$(mktemp -d)"
  LIB_ROOT="$TMPDIR/lib"
  LOCK_ROOT="$LIB_ROOT/.setup.lock"
  mkdir -p "$LIB_ROOT"

  run env TEST_SETUP_SKIP_MAIN=1 "$MODERN_BASH" -c '
    source scripts/test-setup.sh
    LIB_DIR="'"$LIB_ROOT"'"
    LOCK_DIR="'"$LOCK_ROOT"'"
    mkdir -p "$LOCK_DIR"
    printf "%s\n" "$$" > "$LOCK_DIR/pid"
    (
      sleep 1
      rm -rf "$LOCK_DIR"
    ) &
    acquire_setup_lock
    printf "pid=%s lock=%s\n" "$(cat "$LOCK_DIR/pid")" "$LOCK_DIR"
    release_setup_lock
  '
  assert_success
  assert_output --partial "lock=$LOCK_ROOT"
  assert_dir_not_exist "$LOCK_ROOT"
}
