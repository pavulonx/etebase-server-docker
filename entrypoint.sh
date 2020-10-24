#!/bin/sh

set -e

if [ -n "$@" ]; then
    exec "$@"
fi

hLine() { 
  echo "├─────────────────────────────────────────────────────────────────────"
}

manage="$BASE_DIR/manage.py"

ALLOWED_HOSTS=${ALLOWED_HOSTS:-"$(hostname)"}
sed -i "s/%ALLOWED_HOSTS%/$ALLOWED_HOSTS/g" "$BASE_DIR/etebase-server.ini"
cat "$BASE_DIR/etebase-server.ini"


if "$manage" showmigrations -l journal | grep -q ' \[ \] 0001_initial'; then
  hLine  
  echo 'Create Database'
  "$manage" migrate
  
  if [ -n "$SUPER_USER" ]; then
    hLine
    if [ -z "$SUPER_PASS" ]; then
      SUPER_PASS=$(openssl rand -base64 31)
      echo "Admin Password: $SUPER_PASS"
    fi

    echo 'Creating Super User'
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('$SUPER_USER' , '$SUPER_EMAIL', '$SUPER_PASS')" | python manage.py shell
  fi
fi

if [ -z "$USE_POSTGRES" ]; then
  chown -R "$PUID:$PGID" "$DATA_DIR"
fi

hLine
"$manage" showmigrations --list | grep -v '\[X\]'
"$manage" migrate

if [ ! -e "$STATIC_DIR/static/admin" ] || [ ! -e "$STATIC_DIR/static/rest_framework" ]; then
	echo 'Static files are missing, running manage.py collectstatic...'
	mkdir -p "$STATIC_DIR/static"
	"$manage" collectstatic
	chown -R "$PUID:$PGID" "$STATIC_DIR"
  chmod -R a=rX "$STATIC_DIR"
fi

hLine
echo 'Starting ETEBASE server'
daphne -b 0.0.0.0 -p "$PORT" etebase_server.asgi:application
