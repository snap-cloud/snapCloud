#! /usr/bin/env bash

# A simple wrapper because `lapis migrate` is broken.
lapis exec 'require("lapis.db.migrations").run_migrations(require("migrations"))'

# After running migrations, update cloud.sql
pg_dump -d snapcloud -s -O --no-acl > cloud.sql
# Add the *data* from lapis migrations, so you can restore simply with cloud.sql
pg_dump -d snapcloud -a -t lapis_migrations -O --no-acl >> cloud.sql
