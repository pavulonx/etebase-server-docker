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
server_ini="$base_dir/etebase-server.ini"
static_dir=/var/www/etebase
config_templates="$base_dir/config_templates"

# ADJUST INI CONFIG
# TODO: better sed substitution or use other method
if [ -n "$PG_DB_NAME" ] && [ -n "$PG_USER" ] && [ -n "$PG_PASSWD" ] && [ -n "$PG_HOST" ]; then
  cp -f "$config_templates/etebase-server-postgres.ini" "$server_ini"
  PG_PORT=${PG_PORT:-5432}
  sed -i "s/%PG_DB_NAME%/$PG_DB_NAME/g" "$server_ini"
  sed -i "s/%PG_USER%/$PG_USER/g" "$server_ini"
  sed -i "s/%PG_PASSWD%/$PG_PASSWD/g" "$server_ini"
  sed -i "s/%PG_HOST%/$PG_HOST/g" "$server_ini"
  sed -i "s/%PG_PORT%/$PG_PORT/g" "$server_ini"
  set -e

  # wait for postgres
  until PGPASSWORD=$PG_PASSWD psql -h "$PG_HOST" -U "$PG_USER" -c '\q'; do
    >&2 echo "Postgres is unavailable - sleeping"
    sleep 1
  done
  >&2 echo "Postgres is up, proceeding"

else
  cp -f "$config_templates/etebase-server-sqlite.ini" "$server_ini"
  ETEBASE_DB_NAME=${ETEBASE_DB_NAME:-db.sqlite3}
  sed -i "s/%ETEBASE_DB_NAME%/$ETEBASE_DB_NAME/g" "$server_ini"
fi

ALLOWED_HOSTS=${ALLOWED_HOSTS:-localhost}
sed -i "s/%ALLOWED_HOSTS%/$ALLOWED_HOSTS/g" "$server_ini"

cat "$server_ini"
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

if [ ! -e "$static_dir/static/admin" ] || [ ! -e "$static_dir/static/rest_framework" ]; then
  echo 'Static files are missing, running manage.py collectstatic...'
  mkdir -p "$static_dir/static"
  "$manage" collectstatic
  #  chown -R $PUID:$PGID "$static_dir"
  chmod -R a=rX "$static_dir"
fi

hLine
echo 'Starting ETEBASE server'
daphne -b 0.0.0.0 -p "$PORT" etebase_server.asgi:application
