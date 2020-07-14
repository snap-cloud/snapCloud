app: lapis server
db: (pg_ctl status -D ${PGDATA=/var/lib/postgresql/9.5/main} && while true; do sleep 10; done;) || pg_ctl start -W -D ${PGDATA=/var/lib/postgresql/9.5/main}
frontend: cd site && Snippets/build.sh --watch
# Install maildev with npm i -g maildev
# Access sent emails at http://localhost:1080
emails: (type maildev &>/dev/null && maildev --incoming-user cloud --incoming-pass cloudemail) || while true; do sleep 10; done;
