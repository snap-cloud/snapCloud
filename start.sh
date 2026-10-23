#!/bin/bash
source .env
if [[ $1 != "--no-tor" ]]; then
    wget https://check.torproject.org/torbulkexitlist -O lib/torbulkexitlist
fi

# Compiled CSS is committed, so servers don't need sass. In development, drop
# any pre-compressed .css.gz first so nginx's gzip_static doesn't serve a stale
# copy after sass rewrites the .css. On servers, bin/deploy makes fresh ones.
if [[ "$LAPIS_ENVIRONMENT" == 'development' ]]; then
    rm -f static/style/compiled/*.css.gz
    sass --watch static/scss/:static/style/compiled/ --style compressed &
fi
authbind --deep lapis server $LAPIS_ENVIRONMENT
