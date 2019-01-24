#! /usr/bin/env bash

# A simple wrapper because `lapis migrate` is broken.
lapis exec 'require("lapis.db.migrations").run_migrations(require("migrations"))'