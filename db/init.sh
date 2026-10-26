# Snap!Cloud DB initialisation script
# to be run from the root of the repo, or called by bin/lapis-migrate

# Keep a DATABASE_NAME passed in by bin/lapis-migrate over the one in .env
DB_NAME_OVERRIDE="$DATABASE_NAME"
source .env
DATABASE_NAME="${DB_NAME_OVERRIDE:-$DATABASE_NAME}"
echo "Setting up $DATABASE_NAME";

# This displays an error if the db exists, but is a no-op.
createdb "$DATABASE_NAME";

psql -d "$DATABASE_NAME" -a -f db/schema.sql;
psql -d "$DATABASE_NAME" -a -f db/seeds.sql;
