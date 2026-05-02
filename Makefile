.PHONY: annotate install-annotate install migrate deploy test test-lua test-e2e test-a11y lint

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
	open_command := xdg-open
	luarocks_command := luarocks
endif
ifeq ($(UNAME), Darwin)
	open_command := open
	luarocks_command := bin/luarocks-macos
endif

default:
	@echo "Please specify a target."

annotate:
	lapis annotate --preload-module "models" models/*.lua

install-annotate:
	$(luarocks_command) install --lua-version=5.1 https://raw.githubusercontent.com/snap-cloud/lapis-annotate/support-native-lua/lapis-annotate-dev-1.rockspec

install:
	LUAROCKS=$(luarocks_command) bin/install-lua-deps.sh
	npm install
	$(MAKE) install-annotate

db:
	db/init.sh

migrate:
	bin/lapis-migrate

branch ?= $(shell git rev-parse --abbrev-ref HEAD)
deploy:
	ssh snap.berkeley.edu "cd snapCloud/; bin/deploy ${branch}"
	$(open_command) "https://snap.berkeley.edu/"

deploy-staging:
	ssh staging.snap.berkeley.edu "cd snapCloud/; bin/deploy ${branch}"
	$(open_command) "https://staging.snap.berkeley.edu/"

# -----------------------------------------------------------------------------
# Test suite
#
# `make test`      - run everything (lint + busted + playwright + a11y)
# `make lint`      - luacheck only
# `make test-lua`  - busted specs only
# `make test-e2e`  - Playwright end-to-end specs only
# `make test-a11y` - axe-core accessibility specs only
# -----------------------------------------------------------------------------
lint:
	luacheck .

test-lua:
	LAPIS_ENVIRONMENT=test DATABASE_NAME=snapcloud_test busted --config-file=.busted

test-e2e:
	LAPIS_ENVIRONMENT=test DATABASE_NAME=snapcloud_test npx playwright test --grep-invert "@axe"

test-a11y:
	LAPIS_ENVIRONMENT=test DATABASE_NAME=snapcloud_test npx playwright test --grep "@axe"

test: lint test-lua test-e2e test-a11y
