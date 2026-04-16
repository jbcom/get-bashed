#!/usr/bin/env bats

load test_helper

@test "workflows declare top-level least-privilege permissions" {
  for workflow in \
    .github/workflows/ci.yml \
    .github/workflows/codeql.yml \
    .github/workflows/cd.yml \
    .github/workflows/release.yml \
    .github/workflows/scorecard.yml \
    .github/workflows/automerge.yml
  do
    run grep -F 'permissions: {}' "$workflow"
    assert_success
  done
}

@test "mutable GitHub scopes are granted at the job level where needed" {
  run grep -F 'pull-requests: write' .github/workflows/cd.yml .github/workflows/automerge.yml
  assert_success

  run grep -F 'pages: write' .github/workflows/cd.yml
  assert_success

  run grep -F 'security-events: write' .github/workflows/codeql.yml .github/workflows/scorecard.yml
  assert_success
}
