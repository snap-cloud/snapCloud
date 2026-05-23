#!/bin/bash
source .env
if [[ $1 != "--no-tor" ]]; then
    wget https://check.torproject.org/torbulkexitlist -O lib/torbulkexitlist
fi

# Drop any pre-compressed .css.gz first so nginx's gzip_static doesn't serve
# a stale copy after sass rewrites the .css. bin/compress regenerates them.
rm -f static/style/compiled/*.css.gz
sass --watch static/scss/:static/style/compiled/ --style compressed &
authbind --deep lapis server $LAPIS_ENVIRONMENT
