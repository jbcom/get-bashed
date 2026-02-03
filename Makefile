# Docs and lint targets for get-bashed.
.PHONY: docs lint

docs:
	./scripts/gen-docs.sh

lint:
	pre-commit run --all-files
