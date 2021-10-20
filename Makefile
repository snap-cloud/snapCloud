
SHELL := /bin/bash
CURRENT_DB=$(shell source .env && lua5.1 -e 'print(require("lapis.config").get().postgres.database)')
CURRENT_ENVIRONMENT=$(shell source .env && lua5.1 -e 'print(require("lapis.config").get()._name)')

.PHONY: init_schema install

install::
	luarocks install --lua-version 5.1 snap-cloud-beta-0.rockspec

init_schema::
	source .env && createdb -U ${DATABASE_USERNAME} ${CURRENT_DB}
	cat cloud.sql | psql -U ${DATABASE_USERNAME} ${CURRENT_DB}

migrate::
	source .env && lapis migrate
	make cloud.sql

cloud.sql::
	source .env && pg_dump -s -U ${DATABASE_USERNAME} ${CURRENT_DB} > cloud.sql
	source .env && pg_dump -a -t lapis_migrations -U ${DATABASE_USERNAME} ${CURRENT_DB} >> cloud.sql

# routes:
# 	lapis exec 'require "cmd.routes"' --trace

# save a copy of dev database into dev_backup
checkpoint:
	mkdir -p dev_backup
	pg_dump -F c -U ${DATABASE_USERNAME} ${CURRENT_DB} > dev_backup/$$(date +%F_%H-%M-%S).dump

# restore latest dev backup
restore_checkpoint::
	-dropdb -U ${DATABASE_USERNAME} ${CURRENT_DB}
	createdb -U ${DATABASE_USERNAME} ${CURRENT_DB}
	pg_restore -U ${DATABASE_USERNAME} -d ${CURRENT_DB} $$(find dev_backup | grep \.dump | sort -V | tail -n 1)

# This only works if you have snap-cloud/lapis-annotate installed locally.
annotate_models:
	lapis annotate models/*.lua

# https://stackoverflow.com/a/26339924
.PHONY: help
help:
	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
