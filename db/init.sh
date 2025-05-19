# Snap!Cloud DB initalisation script
# to be run from the root of the repo, or called by bin/lapis-migrate

source .env
echo "Setting up $DATABASE_NAME";

# This displays an error if the db exists, but is a no-op.
createdb $DATABASE_NAME;

psql -d $DATABASE_NAME -a -f db/schema.sql;
psql -d $DATABASE_NAME -a -f db/seeds.sql;
