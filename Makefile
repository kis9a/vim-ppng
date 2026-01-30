.DEFAULT_GOAL := help
SHELL := /bin/bash

PWD := $(shell realpath $(dir $(lastword $(MAKEFILE_LIST))))
DEPS_DIR := $(PWD)/.deps

.PHONY: init deps tester linter lint test help clean
.PHONY: lint-vint vint-int check-vint

THEMIS_URL    := https://github.com/thinca/vim-themis.git
THEMIS_DIR    := $(DEPS_DIR)/vim-themis
THEMIS_COMMIT :=

VIMLPARSER_URL    := https://github.com/ynkdir/vim-vimlparser.git
VIMLPARSER_DIR    := $(DEPS_DIR)/vim-vimlparser
VIMLPARSER_COMMIT :=

VIMLINT_URL    := https://github.com/syngan/vim-vimlint.git
VIMLINT_DIR    := $(DEPS_DIR)/vim-vimlint
VIMLINT_COMMIT :=

LINT_DIRS ?= autoload plugin test

define CLONE_AND_OPTIONAL_PIN
	@set -euo pipefail; \
	url="$(1)"; dir="$(2)"; commit="$(3)"; \
	mkdir -p "$(DEPS_DIR)"; \
	if [ ! -d "$$dir/.git" ]; then \
		git clone "$$url" "$$dir"; \
	fi; \
	if [[ "$$commit" =~ ^[0-9a-fA-F]{7,40}$$ ]]; then \
		git -C "$$dir" checkout -q --detach "$$commit"; \
	fi; \
	echo "OK: $$dir @ $$(git -C "$$dir" rev-parse --short HEAD)"
endef

init: linter tester ## init

deps: tester linter ## clone deps (optionally pin)

tester: $(THEMIS_DIR) ## clone tester

linter: $(VIMLPARSER_DIR) $(VIMLINT_DIR) ## clone linter

$(THEMIS_DIR):
	$(call CLONE_AND_OPTIONAL_PIN,$(THEMIS_URL),$(THEMIS_DIR),$(THEMIS_COMMIT))

$(VIMLPARSER_DIR):
	$(call CLONE_AND_OPTIONAL_PIN,$(VIMLPARSER_URL),$(VIMLPARSER_DIR),$(VIMLPARSER_COMMIT))

$(VIMLINT_DIR):
	$(call CLONE_AND_OPTIONAL_PIN,$(VIMLINT_URL),$(VIMLINT_DIR),$(VIMLINT_COMMIT))

test: tester ## testing with vim-themis
	$(THEMIS_DIR)/bin/themis --reporter spec -r test

lint: linter ## linting with vimlint
	$(VIMLINT_DIR)/bin/vimlint.sh \
		-l $(VIMLINT_DIR) \
		-p $(VIMLPARSER_DIR) \
		-e EVL102.l:_=1 -c func_abort=1 \
		$(LINT_DIRS) 2>&1

lint-vint: check-vint ## linting with vint
	vint plugin autoload test

vint-int: ## install vint using pip
	pip install vint

check-vint: ## check vint command exists
	command -v vint >/dev/null 2>&1

clean: ## remove cloned deps
	rm -rf $(DEPS_DIR)

help: ### help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
