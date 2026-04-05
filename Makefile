SHELL := /bin/bash

SUBMODULES := aerospike-py aerospike-ce-kubernetes-operator \
              aerospike-cluster-manager aerospike-ce-ecosystem-plugins \
              project-hub

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available commands
	@echo "Aerospike CE Ecosystem — Workspace"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "%-20s %s\n", "Target", "Description"; printf "%-20s %s\n", "------", "-----------"} /^[a-zA-Z_-]+:.*##/ {printf "%-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

##@ Setup

.PHONY: init
init: ## Initialize all submodules (recursive)
	git submodule update --init --recursive

.PHONY: pre-commit-install
pre-commit-install: ## Install pre-commit hooks (workspace + all submodules)
	pre-commit install --hook-type pre-commit --hook-type commit-msg
	git submodule foreach 'if [ -f .pre-commit-config.yaml ]; then pre-commit install; fi'

.PHONY: init-ssh
init-ssh: ## Convert submodule URLs to SSH and initialize
	@git submodule foreach 'url=$$(git remote get-url origin); ssh_url=$$(echo $$url | sed "s|https://github.com/|git@github.com:|"); git remote set-url origin $$ssh_url; echo "  → $$ssh_url"'
	git submodule update --init --recursive

##@ Sync

.PHONY: pull-all
pull-all: ## Pull latest main for all submodules
	git submodule foreach 'git checkout main 2>/dev/null || git checkout master; git pull --ff-only'

.PHONY: fetch-all
fetch-all: ## Fetch all remotes for all submodules
	git submodule foreach 'git fetch --all --prune'

.PHONY: status
status: ## Show git status of all submodules
	@git submodule foreach --quiet 'echo "=== $$name ==="; git status -sb; echo'

.PHONY: branches
branches: ## Show current branch of each submodule
	@git submodule foreach --quiet 'printf "%-45s %s\n" "$$name" "$$(git branch --show-current)"'

.PHONY: log-all
log-all: ## Show last 3 commits for each submodule
	@git submodule foreach --quiet 'echo "=== $$name ==="; git log --oneline -3; echo'

##@ Build

.PHONY: build-py
build-py: ## Build aerospike-py (Rust + Python)
	cd aerospike-py && make build

.PHONY: build-acko
build-acko: ## Build ACKO operator
	cd aerospike-ce-kubernetes-operator && make build

.PHONY: build-cm
build-cm: ## Build cluster-manager
	cd aerospike-cluster-manager && make build

.PHONY: build-docs
build-docs: ## Build project-hub Docusaurus site
	cd project-hub/docs && npm ci && npm run build

##@ Test

.PHONY: test-py
test-py: ## Run aerospike-py unit tests
	cd aerospike-py && make test-unit

.PHONY: test-acko
test-acko: ## Run ACKO unit + integration tests
	cd aerospike-ce-kubernetes-operator && make test

.PHONY: test-cm
test-cm: ## Run cluster-manager tests (backend + frontend)
	cd aerospike-cluster-manager && make test

##@ Lint

.PHONY: lint-py
lint-py: ## Lint aerospike-py
	cd aerospike-py && make lint

.PHONY: lint-acko
lint-acko: ## Lint ACKO
	cd aerospike-ce-kubernetes-operator && make fmt && make vet

.PHONY: lint-cm
lint-cm: ## Lint cluster-manager
	cd aerospike-cluster-manager && make lint

.PHONY: lint-all
lint-all: lint-py lint-acko lint-cm ## Lint all repos

##@ Infrastructure

.PHONY: start-aerospike
start-aerospike: ## Start local Aerospike CE container
	cd aerospike-py && make run-aerospike-ce

.PHONY: stop-aerospike
stop-aerospike: ## Stop local Aerospike CE container
	cd aerospike-py && make stop-aerospike-ce

.PHONY: start-cm
start-cm: ## Start cluster-manager full stack (Podman Compose)
	cd aerospike-cluster-manager && make up

.PHONY: stop-cm
stop-cm: ## Stop cluster-manager
	cd aerospike-cluster-manager && make down
