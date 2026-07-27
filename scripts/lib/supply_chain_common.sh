#!/usr/bin/env bash

has_regex() {
  local pattern="$1"
  shift
  grep -Eq "$pattern" "$@"
}

resolve_repo_slug() {
  local remote_name
  local remote_url
  local repo_slug

  if [ -n "${GET_BASHED_REPO_SLUG:-}" ]; then
    printf '%s\n' "$GET_BASHED_REPO_SLUG"
    return 0
  fi

  # A repo's `origin` may point at a non-GitHub host (e.g. a Gitea
  # mirror source-of-truth) while a `github` remote carries the actual
  # GitHub location. Check remotes in that preference order and only
  # accept a match whose host is actually github.com — a non-GitHub
  # URL that happens to contain a `/` must not be mistaken for a slug.
  if command -v git >/dev/null 2>&1; then
    for remote_name in github origin upstream; do
      remote_url="$(git -C "$REPO_ROOT" config --get "remote.${remote_name}.url" 2>/dev/null || true)"
      [ -n "$remote_url" ] || continue

      case "$remote_url" in
        git@github.com:*|https://github.com/*|ssh://git@github.com/*|git://github.com/*)
          repo_slug="${remote_url#git@github.com:}"
          repo_slug="${repo_slug#https://github.com/}"
          repo_slug="${repo_slug#ssh://git@github.com/}"
          repo_slug="${repo_slug#git://github.com/}"
          repo_slug="${repo_slug%.git}"
          if [[ "$repo_slug" == */* ]]; then
            printf '%s\n' "$repo_slug"
            return 0
          fi
          ;;
      esac
    done
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
