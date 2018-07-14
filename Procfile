app: lapis server
db: postgres -D /usr/local/var/postgres
frontend: site/snippets/build.sh --watch
# Install maildev with npm i -g maildev
# Access sent emails at http://localhost:($PORT + 2)
emails: type maildev &>/dev/null && maildev -w $(expr $PORT + 2) --incoming-user cloud --incoming-password cloudemail
