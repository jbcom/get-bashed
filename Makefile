# Docs and lint targets for get-bashed.
.PHONY: docs lint test

docs:
	./scripts/gen-docs.sh

lint:
	pre-commit run --all-files

test:
	./scripts/test-setup.sh
	bats tests
