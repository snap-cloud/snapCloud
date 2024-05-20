.PHONY: annotate install-annotate install-deps migrate

default:
	@echo "Please specify a target."

annotate:
	lapis annotate --preload-module "models" models/*.lua

install-annotate:
	luarocks install --lua-version=5.1 https://raw.githubusercontent.com/snap-cloud/lapis-annotate/support-native-lua/lapis-annotate-dev-1.rockspec

install-deps:
	bin/luarocks-macos install --only-deps snapcloud-dev-0.rockspec
	install-annotate

migrate:
	bin/lapis-migrate
