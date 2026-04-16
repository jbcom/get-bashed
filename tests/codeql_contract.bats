#!/usr/bin/env bats

load test_helper

@test "repository carries a repo-owned CodeQL workflow with pinned actions" {
  run test -f .github/workflows/codeql.yml
  assert_success

  run grep -F 'name: CodeQL' .github/workflows/codeql.yml
  assert_success

  run grep -F 'language: [actions, python]' .github/workflows/codeql.yml
  assert_success

  run grep -F 'queries: security-extended' .github/workflows/codeql.yml
  assert_success

  run grep -F 'github/codeql-action/init@' .github/workflows/codeql.yml
  assert_success

  run grep -F 'github/codeql-action/autobuild@' .github/workflows/codeql.yml
  assert_success

  run grep -F 'github/codeql-action/analyze@' .github/workflows/codeql.yml
  assert_success
}

@test "security docs and agent guidance mention the repo-owned CodeQL workflow" {
  run grep -F 'codeql.yml' README.md docs/README.md docs/TESTING.md docs/reference/security.md docs/reference/supply-chain.md AGENTS.md
  assert_success

  run grep -F 'CodeQL' scripts/supply_chain_verify.sh
  assert_success
}
