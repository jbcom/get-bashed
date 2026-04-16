#!/usr/bin/env bats

load test_helper

@test "documented config keys match generated config output" {
  TMPDIR="$(mktemp -d)"
  HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  env HOME="$HOME" ./install.sh --auto --prefix "$HOME/.get-bashed" --name "Jane Doe" --email "jane@example.com" >/dev/null

  while IFS= read -r line; do
    key="${line#export }"
    key="${key%%=*}"
    run grep -F "$key" docs/CONFIG.md
    assert_success
  done < <(grep '^export GET_BASHED_' "$HOME/.get-bashed/get-bashedrc.sh")
}

@test "documentation references only current workflow files" {
  run rg -n "docs.yml|pr-title.yml|release-please.yml|autofix.yml|dependabot-automerge.yml" README.md AGENTS.md STANDARDS.md docs
  assert_failure

  run grep -F "cd.yml" README.md
  assert_success
  run grep -F "ci.yml" AGENTS.md
  assert_success
  run grep -F "release.yml" README.md
  assert_success
  run grep -F "scorecard.yml" AGENTS.md
  assert_success
  run grep -F "scorecard.yml" docs/README.md
  assert_success
  run grep -F "scorecard.yml" docs/reference/supply-chain.md
  assert_success
}

@test "ci workflow includes dedicated WSL validation on windows-2025" {
  run grep -F 'runs-on: windows-2025' .github/workflows/ci.yml
  assert_success

  run grep -F 'wsl.exe --install --distribution $distro --no-launch --web-download' .github/workflows/ci.yml
  assert_success

  run rg -n 'rather than dedicated runner validation|Linux-compatible path rather than a dedicated WSL runner' README.md AGENTS.md docs
  assert_failure
}

@test "installer catalog documentation is populated" {
  run grep -F '| `bash` |' docs/INSTALLERS.md
  assert_success
}

@test "docs surface includes getting-started, reference, api, and docs-site installer" {
  run grep -F 'html_extra_path = ["public"]' docs/conf.py
  assert_success

  run grep -F 'getting-started/index' docs/index.md
  assert_success

  run grep -F 'reference/index' docs/index.md
  assert_success

  run grep -F 'api/index' docs/index.md
  assert_success

  run grep -F 'security' docs/reference/index.md
  assert_success

  run grep -F 'get-bashed-<version>-unix.tar.gz' docs/getting-started/index.md
  assert_success

  run grep -F 'jbcom/pkgs' docs/getting-started/downloads.md
  assert_success

  run test -f docs/public/install.sh
  assert_success
}

@test "docs tooling includes linkcheck and a local ci target" {
  run grep -F 'env_list = docs, docs-linkcheck' tox.ini
  assert_success

  run grep -F 'sphinx-build docs/ docs/_build/linkcheck -b linkcheck' tox.ini
  assert_success

  run grep -F 'uvx tox -e docs,docs-linkcheck' Makefile
  assert_success

  run grep -F 'ci:' Makefile
  assert_success

  run grep -F 'uvx tox -e docs,docs-linkcheck' .github/workflows/ci.yml
  assert_success
}

@test "repository includes a supply-chain verifier and documents verify-security" {
  run test -f scripts/supply_chain_verify.sh
  assert_success

  run grep -F 'verify-security:' Makefile
  assert_success

  run grep -F 'make verify-security' README.md docs/README.md docs/TESTING.md docs/reference/testing.md docs/reference/security.md
  assert_success

  run grep -F './scripts/supply_chain_verify.sh' .github/workflows/ci.yml
  assert_success
}

@test "repository carries a repo-owned dependabot configuration" {
  run test -f .github/dependabot.yml
  assert_success

  run grep -F 'package-ecosystem: "github-actions"' .github/dependabot.yml
  assert_success

  run grep -F 'commit-message:' .github/dependabot.yml
  assert_success

  run grep -F 'automated Dependabot security fixes' README.md docs/reference/security.md docs/reference/supply-chain.md
  assert_success

  run grep -F 'secret scanning push protection' README.md docs/reference/security.md docs/reference/supply-chain.md docs/TESTING.md
  assert_success
}

@test "repository includes a branch protection verifier and documents exact required checks" {
  run test -f scripts/verify_branch_protection.sh
  assert_success

  run grep -F 'Quality (ubuntu-latest)' scripts/verify_branch_protection.sh
  assert_success

  run grep -F 'Quality (macos-latest)' scripts/verify_branch_protection.sh
  assert_success

  run grep -F 'Quality (wsl-ubuntu)' scripts/verify_branch_protection.sh
  assert_success

  run grep -F 'SonarQube Scan' scripts/verify_branch_protection.sh
  assert_success

  run grep -F 'require_code_owner_reviews' scripts/verify_branch_protection.sh
  assert_success

  run grep -F 'make verify-branch-protection' docs/CONFIG.md docs/TESTING.md docs/reference/release-checklist.md docs/reference/release-verification.md docs/reference/testing.md README.md
  assert_success
}

@test "repository includes a scripted CodeQL governance reconciliation path" {
  run test -f scripts/reconcile_codeql_governance.sh
  assert_success

  run grep -F 'reconcile-codeql-governance:' Makefile
  assert_success

  run grep -F 'make reconcile-codeql-governance' README.md docs/TESTING.md docs/reference/security.md docs/reference/supply-chain.md docs/reference/release-checklist.md
  assert_success
}

@test "release workflows use draft-first checked-in publication scripts" {
  run grep -F '"draft": true' release-please-config.json
  assert_success

  run grep -F '"force-tag-creation": true' release-please-config.json
  assert_success

  run grep -F 'id: release' .github/workflows/cd.yml
  assert_success

  run grep -F 'steps.release.outputs.release_created' .github/workflows/cd.yml
  assert_success

  run grep -F 'scripts/publish_draft_release.sh' .github/workflows/cd.yml
  assert_success

  run grep -F 'secrets.CI_GITHUB_TOKEN || github.token' .github/workflows/cd.yml
  assert_success

  run grep -F 'scripts/build_release_artifact.sh' .github/workflows/release.yml
  assert_success

  run grep -F 'scripts/release_validate.sh' .github/workflows/release.yml
  assert_success

  run grep -F 'scripts/publish_draft_release.sh' .github/workflows/release.yml
  assert_success

  run grep -F 'scripts/verify_published_release.sh' .github/workflows/release.yml
  assert_success

  run grep -F 'scripts/publish_pkg_pr.sh' .github/workflows/release.yml
  assert_success

  run grep -F 'workflow_dispatch' .github/workflows/release.yml
  assert_success

  run rg -n 'types: \[published\]' .github/workflows/release.yml
  assert_failure

  run grep -F 'gh attestation verify "$WINDOWS_ARCHIVE"' scripts/verify_published_release.sh
  assert_success

  run grep -F 'verify-immutable-release-governance:' Makefile
  assert_success

  run grep -F 'reconcile-immutable-release-governance:' Makefile
  assert_success

  run test -f scripts/verify_immutable_release_governance.sh
  assert_success

  run test -f scripts/reconcile_immutable_release_governance.sh
  assert_success
}

@test "repository includes a dedicated scorecard workflow" {
  run test -f .github/workflows/scorecard.yml
  assert_success

  run grep -F 'ossf/scorecard-action' .github/workflows/scorecard.yml
  assert_success
}

@test "installer code does not resolve asdf latest at runtime" {
  run rg -n 'asdf (latest|install .+ latest)' installers installlib bin scripts
  assert_failure
}

@test "curl fallbacks are pinned instead of using moving HEAD URLs" {
  run rg -n 'raw\\.githubusercontent\\.com/.+/HEAD/' installers scripts README.md TOOLS.md docs AGENTS.md --glob '!scripts/supply_chain_verify.sh'
  assert_failure
}

@test "runtime and pipx helpers do not use floating package specs" {
  run rg -n 'npm install -g (@google/gemini-cli|@sonar/scan)([[:space:]]|$)' bashrc.d
  assert_failure

  run rg -n 'pipx install \"\\$pkg\"|python3 -m pip install --user \"\\$(id|pkg)\"' installers
  assert_failure
}

@test "actionlint fallback pins per-platform checksums" {
  run grep -F 'GET_BASHED_ACTIONLINT_SHA256["linux_amd64"]' installers/sources.sh
  assert_success

  run grep -F 'GET_BASHED_ACTIONLINT_SHA256["darwin_arm64"]' installers/sources.sh
  assert_success
}

@test "shell-facing files stay within the 300 line cap" {
  run "$MODERN_BASH" -c '
    set -euo pipefail
    status=0
    for file in install.sh install.bash bashrc bash_profile bin/ram_usage installers/_helpers.sh installers/tools.sh scripts/*.sh installlib/*.sh installers/lib/*.sh bashrc.d/*.sh; do
      lines=$(wc -l < "$file")
      if [[ "$lines" -gt 300 ]]; then
        printf "%s %s\n" "$lines" "$file"
        status=1
      fi
    done
    exit "$status"
  '
  assert_success
}

@test "bash_it installs to the runtime path expected by bash-it integration" {
  run grep -F 'tool_target_dir bash_it "bash-it"' installers/tools.sh
  assert_success
}

@test "tests do not hardcode a macOS-only bash path in commands" {
  run rg -n '/opt/homebrew/bin/bash' tests --glob '!test_helper.bash' --glob '!docs_contract.bats'
  assert_failure
}

@test "make targets bootstrap the same helper path as CI" {
  run grep -F './scripts/ci-setup.sh "shdoc,uv"' Makefile
  assert_success

  run grep -F './scripts/ci-setup.sh "bats"' Makefile
  assert_success
}

@test "ci bootstrap disables Homebrew auto-update for deterministic tool installs" {
  run grep -F 'HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE:-1}"' scripts/ci-setup.sh
  assert_success

  run grep -F 'HOMEBREW_NO_INSTALL_CLEANUP="${HOMEBREW_NO_INSTALL_CLEANUP:-1}"' scripts/ci-setup.sh
  assert_success
}

@test "runtime modules resolve Homebrew state through brew --prefix" {
  run rg -n 'dirname "\\$\\(dirname "\\$\\(command -v brew\\)\\)"|/opt/homebrew/etc/profile\\.d/bash_completion\\.sh|/usr/local/etc/profile\\.d/bash_completion\\.sh|/opt/homebrew/opt/asdf/libexec/asdf\\.sh|/usr/local/opt/asdf/libexec/asdf\\.sh' bashrc.d
  assert_failure

  run grep -F 'prefix="$("$brew_bin" --prefix 2>/dev/null || true)"' bashrc.d/10-helpers.sh
  assert_success

  run rg -n 'get_brew_prefix' bashrc.d/20-path.sh bashrc.d/30-buildflags.sh bashrc.d/40-completions.sh bashrc.d/60-asdf.sh
  assert_success
}

@test "bash_profile uses brew shellenv instead of hand-rolled exports" {
  run rg -n 'brew shellenv' bash_profile
  assert_success

  run rg -n 'HOMEBREW_CELLAR=.*Cellar|dirname "\\$\\(dirname "\\$\\(command -v brew\\)\\)"' bash_profile
  assert_failure
}

@test "bootstrap uses the shared pinned Homebrew source manifest" {
  run grep -F 'installers/bootstrap_sources.sh' install.sh
  assert_success

  run grep -F 'GET_BASHED_CURL_SOURCES["brew"]="${GET_BASHED_BOOTSTRAP_BREW_URL}"' installers/sources.sh
  assert_success

  run grep -F 'GET_BASHED_CURL_CMD["brew"]="${GET_BASHED_BOOTSTRAP_BREW_CMD}"' installers/sources.sh
  assert_success

  run rg -n 'archive/refs/heads/main\\.tar\\.gz|archive/refs/heads/.+\\.tar\\.gz' install.sh installers/bootstrap_sources.sh README.md docs
  assert_failure
}
