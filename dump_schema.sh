#!/bin/sh
echo "Please provide the password for the BeetleCloud database owner"
pg_dump -W -Fp -s -h localhost -U `cat config.lua | grep user | cut -d\' -f2 | tail -n1` `cat config.lua | grep database | cut -d\' -f2 | tail -n1` > cloud.sql
