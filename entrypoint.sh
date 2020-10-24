#!/bin/sh

set -e

if [ -n "$@" ]; then
  exec "$@"
fi

hLine() {
  echo "├─────────────────────────────────────────────────────────────────────"
}

PORT=$PORT
ALLOWED_HOSTS=$ALLOWED_HOSTS
ETEBASE_DB_NAME=$ETEBASE_DB_NAME
SUPER_USER=$SUPER_USER
SUPER_EMAIL=$SUPER_EMAIL
SUPER_PASS=$SUPER_PASS

base_dir=/etebase
manage="$base_dir/manage.py"

# ADJUST INI CONFIG
ALLOWED_HOSTS=${ALLOWED_HOSTS:-localhost}
sed -i "s/%ALLOWED_HOSTS%/$ALLOWED_HOSTS/g" "$base_dir/etebase-server.ini"

ETEBASE_DB_NAME=${ETEBASE_DB_NAME:-db.sqlite3}
sed -i "s/%ETEBASE_DB_NAME%/$ETEBASE_DB_NAME/g" "$base_dir/etebase-server.ini"

cat "$base_dir/etebase-server.ini"
echo

if "$manage" showmigrations -l | grep -q ' \[ \] 0001_initial'; then
  hLine
  echo 'Create Database'
  "$manage" migrate

  if [ -n "$SUPER_USER" ] && [ -n "$SUPER_EMAIL" ]; then
    hLine
    if [ -z "$SUPER_PASS" ]; then
      SUPER_PASS=$(openssl rand -base64 31)
      echo "Admin $SUPER_USER password: $SUPER_PASS"
    fi

    echo 'Creating Super User'

    export DJANGO_SUPERUSER_PASSWORD=$SUPER_PASS
    "$manage" createsuperuser --username "$SUPER_USER" --email "$SUPER_EMAIL" --noinput
    #    "$manage" shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('$SUPER_USER' , '$SUPER_EMAIL', '$SUPER_PASS')"
  fi
fi

hLine
"$manage" showmigrations --list | grep -v '\[X\]'
"$manage" makemigrations
"$manage" migrate

hLine
echo 'Starting ETEBASE server'
daphne -b 0.0.0.0 -p "$PORT" etebase_server.asgi:application
