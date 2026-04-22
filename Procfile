# update_tor: wget https://check.torproject.org/torbulkexitlist -O lib/torbulkexitlist
app: lapis server
# CSS Compilation
saas: npx sass --watch static/scss/:static/style/compiled/ --style compressed
# db: postgres -D ${PG_DATA_DIR=/var/lib/postgresql/9.5/main}
# Install maildev with npm i maildev
# Access sent emails at http://localhost:1080
emails: npx maildev --incoming-user cloud --incoming-pass cloudemail
# Local S3-compatible object storage for testing the R2 integration.
# Install with `brew install minio/stable/minio mc` (macOS) or see
# INSTALL.md. The app reads S3_ENDPOINT etc. from your .env file.
# Bucket bootstrap: bin/setup-minio (run once after minio is up).
minio: minio server tmp/minio-data --address :9000 --console-address :9001
