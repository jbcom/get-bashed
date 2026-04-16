# Docs and lint targets for get-bashed.
PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)
VERSION ?= $(shell git describe --tags --always --dirty | sed 's/^v//')
TAG ?= v$(VERSION)
.PHONY: docs docs-check lint test ci verify-security verify-branch-protection verify-immutable-release-governance reconcile-codeql-governance reconcile-immutable-release-governance package-release smoke-release release-validate verify-published-release

docs:
	bash -c '. ./scripts/ci-setup.sh "shdoc,uv" && PATH="$$GET_BASHED_HOME/bin:$$PATH" ./scripts/gen-docs.sh && ./scripts/validate-docs.sh && uvx tox -e docs'

docs-check:
	bash -c '. ./scripts/ci-setup.sh "shdoc,uv" && PATH="$$GET_BASHED_HOME/bin:$$PATH" ./scripts/gen-docs.sh && ./scripts/validate-docs.sh && uvx tox -e docs,docs-linkcheck'

lint:
	./scripts/pre-commit-ci.sh

test:
	bash -c '. ./scripts/ci-setup.sh "bats" && ./scripts/test-setup.sh && bats tests && ./scripts/verify-install.sh'

ci:
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) docs-check
	$(MAKE) verify-security

verify-security:
	bash ./scripts/supply_chain_verify.sh

verify-branch-protection:
	bash ./scripts/verify_branch_protection.sh

verify-immutable-release-governance:
	bash ./scripts/verify_immutable_release_governance.sh

reconcile-codeql-governance:
	bash ./scripts/reconcile_codeql_governance.sh

reconcile-immutable-release-governance:
	bash ./scripts/reconcile_immutable_release_governance.sh

package-release:
	rm -rf dist/release
	mkdir -p dist/release
	bash ./scripts/build_release_artifact.sh "$(VERSION)" dist/release

smoke-release: package-release
	bash ./scripts/smoke_test_release_artifact.sh "$(VERSION)" dist/release/get-bashed-$(VERSION)-unix.tar.gz
	bash ./scripts/smoke_test_release_artifact.sh "$(VERSION)" dist/release/get-bashed-$(VERSION)-windows.zip

release-validate: package-release
	bash ./scripts/release_validate.sh "$(VERSION)" dist/release

verify-published-release:
	bash ./scripts/verify_published_release.sh "$(TAG)" "jbcom/get-bashed" "jbcom"
