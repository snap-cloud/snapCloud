.PHONY: annotate install-annotate install migrate deploy \
	vendor vendor-bootstrap vendor-fontawesome vendor-filesaver \
	test test-lua test-e2e test-a11y lint

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
	npm ci
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

# Front-end libraries: copy from node_modules into static/vendor and update
# the ?v cache busters in the layout templates. Run `npm ci` first.
NM := node_modules
VENDOR := static/vendor
HEAD := views/layout/head.etlua
SCRIPTS := views/layout/delayed_scripts.etlua

# $(call version,pkg)
version = $$(node -p "require('./$(NM)/$(1)/package.json').version")
# $(call bust,url-path,template,pkg): set ?v<version> on every reference to url-path
bust = perl -pi -e 's{(\Q$(1)\E)(\?v[^"\x27]*)?}{$$1?v'"$(call version,$(3))"'}g' $(2)

vendor: vendor-bootstrap vendor-fontawesome vendor-filesaver

vendor-bootstrap:
	cp $(NM)/bootstrap/dist/css/bootstrap.min.css* $(VENDOR)/style/
	cp $(NM)/bootstrap/dist/js/bootstrap.bundle.min.js* $(VENDOR)/js/
	cp $(NM)/@popperjs/core/dist/umd/popper.min.js $(NM)/@popperjs/core/dist/umd/popper.min.js.map $(VENDOR)/js/
	$(call bust,/static/vendor/style/bootstrap.min.css,$(HEAD),bootstrap)
	$(call bust,/static/vendor/js/bootstrap.bundle.min.js,$(SCRIPTS),bootstrap)

# Wipe the old copy so files removed upstream don't linger.
vendor-fontawesome:
	rm -rf $(VENDOR)/fontawesome
	mkdir -p $(VENDOR)/fontawesome/style
	cp $(NM)/@fortawesome/fontawesome-free/css/all.min.css $(VENDOR)/fontawesome/style/
	cp -R $(NM)/@fortawesome/fontawesome-free/webfonts $(VENDOR)/fontawesome/
	cp $(NM)/@fortawesome/fontawesome-free/LICENSE.txt $(VENDOR)/fontawesome/
	$(call bust,/static/vendor/fontawesome/style/all.min.css,$(HEAD),@fortawesome/fontawesome-free)

vendor-filesaver:
	cp $(NM)/file-saver/dist/FileSaver.min.js* $(VENDOR)/js/
	$(call bust,/static/vendor/js/FileSaver.min.js,$(SCRIPTS),file-saver)

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
