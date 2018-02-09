#!/bin/sh
echo "Please provide the password for the cloud database owner"
pg_dump -W -Fp -s -h localhost -U $DATABASE_USERNAME -d $DATABASE_NAME > cloud.sql
