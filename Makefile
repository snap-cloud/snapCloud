.PHONY: annotate install-annotate install migrate deploy

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
	$(luarocks_command) install --only-deps snapcloud-dev-0.rockspec
	npm install
	$(MAKE) install-annotate

migrate:
	bin/lapis-migrate

branch ?= $(shell git rev-parse --abbrev-ref HEAD)
deploy:
	ssh snap.berkeley.edu "cd snapCloud/; bin/deploy ${branch}"
	$(open_command) "https://snap.berkeley.edu/"

deploy-staging:
	ssh staging.snap.berkeley.edu "cd snapCloud/; bin/deploy ${branch}"
	$(open_command) "https://staging.snap.berkeley.edu/"
