#!/usr/bin/env bats

load test_helper

@test "workflows declare top-level least-privilege permissions" {
  for workflow in \
    .github/workflows/ci.yml \
    .github/workflows/cd.yml \
    .github/workflows/release.yml \
    .github/workflows/scorecard.yml \
    .github/workflows/automerge.yml
  do
    run grep -F 'permissions: {}' "$workflow"
    assert_success
  done
}

@test "codeql.yml declares least-privilege permissions at job level" {
  # codeql.yml is centrally synced from gh-fleet-sync (see its header
  # comment) and locks down permissions on its one job instead of a
  # blanket top-level `permissions: {}`.
  run grep -F 'permissions:' .github/workflows/codeql.yml
  assert_success

  run grep -F 'contents: read' .github/workflows/codeql.yml
  assert_success
}

@test "mutable GitHub scopes are granted at the job level where needed" {
  run grep -F 'pull-requests: write' .github/workflows/cd.yml .github/workflows/automerge.yml
  assert_success

  run grep -F 'pages: write' .github/workflows/cd.yml
  assert_success

  run grep -F 'security-events: write' .github/workflows/codeql.yml .github/workflows/scorecard.yml
  assert_success
}
