#! /bin/bash

# Export a copy of the main db designed to be re-imported into another instance.
pg_dump -d snapcloud --no-owner --clean --if-exists -f snapcloud-export-$today.sql
echo "Exported dump as snapcloud-export-$today.sql";
