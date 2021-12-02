#!/bin/bash
source .env
wget https://check.torproject.org/torbulkexitlist -O lib/torbulkexitlist
authbind --deep lapis server $LAPIS_ENVIRONMENT
