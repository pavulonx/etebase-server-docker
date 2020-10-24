#!/bin/sh
set -e

[ -n "$@" ] && exec "$@"

hLine() {
  echo "├─────────────────────────────────────────────────────────────────────"
}

base_dir=/etebase
manage="$base_dir/manage.py"
server_ini="$base_dir/etebase-server.ini"
static_dir=/var/www/etebase
config_templates="$base_dir/config_templates"

PORT=${PORT:-3735}
DEBUG=$(test "${DEBUG:-false}" = true && echo true || echo false)
ALLOWED_HOSTS=${ALLOWED_HOSTS:-localhost}
AUTO_MIGRATE=$(test "${AUTO_MIGRATE:-false}" = true && echo true || echo false)

SUPER_USER=$SUPER_USER
SUPER_EMAIL=$SUPER_EMAIL
SUPER_PASS=$SUPER_PASS

DATABASE=${DATABASE:-sqlite}

SQLITE_DB_NAME=$SQLITE_DB_NAME

PG_DB_NAME=$PG_DB_NAME
PG_USER=$PG_USER
PG_PASSWD=$PG_PASSWD
PG_HOST=$PG_HOST
PG_PORT=$PG_PORT

sed "
  s/%DEBUG%/$DEBUG/g
  s/%ALLOWED_HOSTS%/$ALLOWED_HOSTS/g
" "$config_templates/etebase-server.ini" >>"$server_ini"
printf "\n" >>"$server_ini"

case "$DATABASE" in
postgres)
  [ -z "$PG_DB_NAME" ] && echo >&2 'PG_DB_NAME is not set!' && exit 1
  [ -z "$PG_USER" ] && echo >&2 'PG_USER is not set' && exit 1
  [ -z "$PG_HOST" ] && echo >&2 'PG_HOST is not set' && exit 1
  PG_PORT=${PG_PORT:-5432}
  sed "
    s/%PG_DB_NAME%/$PG_DB_NAME/g
    s/%PG_USER%/$PG_USER/g
    s/%PG_PASSWD%/$PG_PASSWD/g
    s/%PG_HOST%/$PG_HOST/g
    s/%PG_PORT%/$PG_PORT/g
  " "$config_templates/etebase-server-postgres.ini" >>"$server_ini"
  ;;
sqlite)
  SQLITE_DB_NAME=${SQLITE_DB_NAME:-db.sqlite3}
  sed "
    s/%SQLITE_DB_NAME%/$SQLITE_DB_NAME/g
  " "$config_templates/etebase-server-sqlite.ini" >>"$server_ini"
  ;;
*)
  echo >&2 "Unsupported database $DATABASE"
  exit 1
  ;;
esac

$DEBUG && echo "Server config in $server_ini" && cat "$server_ini"

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
# MIGRATION
"$manage" showmigrations --list | grep -v '\[X\]'
if [ "$AUTO_MIGRATE" = true ]; then
  "$manage" makemigrations
  "$manage" migrate
else
  echo "If necessary please run: docker exec -it $HOSTNAME python manage.py migrate"
fi

if [ ! -e "$static_dir/static/admin" ] || [ ! -e "$static_dir/static/rest_framework" ]; then
  echo 'Static files are missing, running manage.py collectstatic...'
  mkdir -p "$static_dir/static"
  "$manage" collectstatic
  chmod -R a=rX "$static_dir"
fi

hLine
echo 'Starting ETEBASE server'
daphne -b 0.0.0.0 -p "$PORT" etebase_server.asgi:application
