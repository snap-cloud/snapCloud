# update_tor: wget https://check.torproject.org/torbulkexitlist -O lib/torbulkexitlist
app: lapis server
# CSS Compilation
saas: sass --watch static/scss/:static/style/compiled/ --style compressed
# db: postgres -D ${PG_DATA_DIR=/var/lib/postgresql/9.5/main}
# Install maildev with npm i -g maildev
# Access sent emails at http://localhost:1080
emails: type maildev &>/dev/null && maildev --incoming-user cloud --incoming-pass cloudemail
