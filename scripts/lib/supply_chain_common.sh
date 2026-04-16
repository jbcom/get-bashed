#!/usr/bin/env bash

has_regex() {
  local pattern="$1"
  shift
  grep -Eq "$pattern" "$@"
}

resolve_repo_slug() {
  local remote_url
  local repo_slug

  if [ -n "${GET_BASHED_REPO_SLUG:-}" ]; then
    printf '%s\n' "$GET_BASHED_REPO_SLUG"
    return 0
  fi

  if command -v git >/dev/null 2>&1; then
    remote_url="$(git -C "$REPO_ROOT" config --get remote.origin.url 2>/dev/null || true)"
    if [ -n "$remote_url" ]; then
      repo_slug="${remote_url#git@github.com:}"
      repo_slug="${repo_slug#https://github.com/}"
      repo_slug="${repo_slug#ssh://git@github.com/}"
      repo_slug="${repo_slug#git://github.com/}"
      repo_slug="${repo_slug%.git}"
      if [[ "$repo_slug" == */* ]]; then
        printf '%s\n' "$repo_slug"
        return 0
      fi
    fi
  fi

  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    repo_slug="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)"
    if [ -n "$repo_slug" ]; then
      printf '%s\n' "$repo_slug"
      return 0
    fi
  fi

  printf '%s\n' 'jbcom/get-bashed'
}
