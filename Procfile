app: lapis server
db: postgres -D /usr/local/var/postgres
frontend: cd site && Snippets/build.sh --watch
# Install maildev with npm i -g maildev
# Access sent emails at http://localhost:1080
emails: (type maildev &>/dev/null && maildev --incoming-user cloud --incoming-pass cloudemail) || while true; do sleep 10; done;
