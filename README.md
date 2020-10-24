# ![](https://raw.githubusercontent.com/etesync/server/master/icon.svg) EteBase Sever Docker Images

![Release images](https://github.com/rozenj/etebase-server-docker/workflows/Release%20images/badge.svg)
![Build Alpine based image master](https://github.com/rozenj/etebase-server-docker/workflows/Build%20Alpine%20based%20image%20master/badge.svg)
![Build Debian based image master](https://github.com/rozenj/etebase-server-docker/workflows/Build%20Debian%20based%20image%20master/badge.svg)

Docker image for [EteBase](https://www.etebase.com/) based on the [server](https://github.com/etesync/server) repository by [Tom Hacohen](https://github.com/tasn).

## Tags

The following tags are built on latest python image version `3.8.5` and `v0.5.0` tag of EteSync Server 
- `0.5.0-alpine`, `0.5.0`, `alpine`, `latest` - [(release:tags/alpine/Dockerfile)](https://github.com/victor-rds/docker-etesync-server/blob/release/tags/alpine/Dockerfile)
- `0.5.0-debian`, `debian`  [(release:tags/slim/Dockerfile)](https://github.com/victor-rds/docker-etesync-server/blob/release/tags/slim/Dockerfile)

The following tags are built on latest python image version `3.8.5` and `master` branch of EteSync Server 


## Usage
```docker run -d -e SUPER_USER=admin -e SUPER_EMAIL=admin@example.com -p 80:3735 -v /path/on/host:/data rozenj/etesync```

Create a container running EteSync using http protocol.

## Volumes
- `/data`: database file location if using SQLite

## Ports
This image exposes the **3735** TCP Port

### Environment Variables

#### General
- **PORT**: Defines port on which application should be run 
- **AUTO_MIGRATE**: Trigger database update/migration every time the container starts, default: `false `, more details below.
- **ALLOWED_HOSTS**: the ALLOWED_HOSTS settings, must be valid domains separated by ,. default: localhost;
    - // **SECRET_FILE**: Defines file that contains the value for django's SECRET_KEY if not found a new one is generated. default: /etesync/secret.txt.
    - // **LANGUAGE_CODE**: Django language code, default: en-us;
    - // **USE_TZ**: Force Django to use time-zone-aware datetime objects internally, defaults to false;
    - // **TIME_ZONE**: time zone, defaults to UTC;
- **DEBUG**: enables Django Debug mode, not recommended for production defaults to `false`;

#### Database
- **DATABASE**: Database backend, can be set to `sqlite` or `postgres`, defaults to `sqlite`

If *DATABASE* is set to `sqlite`:
- **SQLITE_DB_NAME**: name of the sqlite database file, defaults to `db.sqlite3` 

If *DATABASE* is set to `postgres`:
- **PG_DB_NAME**: PostgreSQL database name 
- **PG_USER**: Database user
- **PG_PASSWD**: User's password
- **PG_HOST**: Host of the database
- **PG_PORT**: Port of the database, default: `5432`

### How to create a Superuser

#### Method 1 Environment Variables on first run.

If these variables are set on the first run it will trigger the creation of a superuser after the database is ready 
(only used if no previous database is found).

- **SUPER_USER**: Username of the django superuser;
- **SUPER_PASS**: Password of the django superuser (optional, one will be generated if not found);
- **SUPER_EMAIL**: Email of the django superuser (optional);

#### Method 2 Python Shell

At any moment after the database is ready, you can create a new superuser by running and following the prompts:

```docker exec -it {container_name} python manage.py createsuperuser```

### Upgrade application and database

If `AUTO_MIGRATE` is not set to `true` you can update by running:

```docker exec -it {container_name} python manage.py migrate```

### _Serving Static Files_

When behind a reverse-proxy/http server compatible `uwsgi` protocol the static files are located at `/var/www/etesync/static`, files will be copied if missing on start.
