#!/bin/bash
source .env
if [[ $1 != "--no-tor" ]]; then
    wget https://check.torproject.org/torbulkexitlist -O lib/torbulkexitlist
fi

sass --watch static/scss/:static/style/compiled/ --style compressed &
authbind --deep lapis server $LAPIS_ENVIRONMENT
