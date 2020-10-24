# ![](https://raw.githubusercontent.com/etesync/server/master/icon.svg) EteBase Sever Docker Images

![Build and Push Base Tags](https://github.com/victor-rds/docker-etesync-server/workflows/Build%20and%20Push%20Base%20Tags/badge.svg?branch=release)
![Build and Push Slim Tags](https://github.com/victor-rds/docker-etesync-server/workflows/Build%20and%20Push%20Slim%20Tags/badge.svg?branch=release)
![Build and Push Alpine Tags](https://github.com/victor-rds/docker-etesync-server/workflows/Build%20and%20Push%20Alpine%20Tags/badge.svg?branch=release)

Docker image for [EteBase](https://www.etebase.com/) based on the [server](https://github.com/etesync/server) repository by [Tom Hacohen](https://github.com/tasn).


## Tags

The following tags are built on latest python image and master branch of EteSync Server 

- `latest` [(release:tags/latest/Dockerfile)](https://github.com/victor-rds/docker-etesync-server/blob/release/tags/base/Dockerfile)
- `slim`  [(release:tags/slim/Dockerfile)](https://github.com/victor-rds/docker-etesync-server/blob/release/tags/slim/Dockerfile)
- `alpine` [(release:tags/alpine/Dockerfile)](https://github.com/victor-rds/docker-etesync-server/blob/release/tags/alpine/Dockerfile)

Starting on v0.3.0 ther will be builds base stable published version of EteSync

- `0.3.0`
- `0.3.0-slim`
- `0.3.0-alpine`

## Usage

```docker run  -d -e SUPER_USER=admin -e SUPER_EMAIL=admin@example.com -p 80:3735 -v /path/on/host:/data rozenj/etesync```

Create a container running EteSync using http protocol.

## Volumes

`/data`: database file location

## Ports

This image exposes the **3735** TCP Port

## Settings and Customization

Custom settings can be added to `/etesync/etesync_site_settings.py`, this file overrides the default `settings.py`, mostly for _Django: The Web framework_ options, this image also uses the some environment variables to set some of these options.

### Environment Variables

- **SERVER**: Defines how the container will serve the application, the options are:
  - `http` Runs using HTTP protocol, this is the default mode.
  - `https` same as above but with TLS/SSL support, see below how to use with your own certificates.
  - `uwsgi` start using uWSGI native protocol, for reverse-proxies/load balances, such as _nginx_, that support this protocol
  - `http-socket` Similar to the first option, but without uWSGI HTTP router/proxy/load-balancer, this recommended for any reverse-proxies/load balances, that support HTTP protocol, like _traefik_
  - `django-server` this mode uses the embedded django http server, `./manage.py runserver :3735`, this is not recommeded but can be useful for debugging
- **PUID** and **PGID**: set user and group when running using uwsgi, default: `1000`;
- **ETESYNC_DB_PATH**: Location of the EteSync SQLite database. default: `/data` volume;
- **AUTO_MIGRATE**: Trigger database update/migration every time the container starts, default: `false `, more details below.
- **SECRET_FILE**: Defines file that contains the value for django's SECRET_KEY if not found a new one is generated. default: /etesync/secret.txt.
- **ALLOWED_HOSTS**: the ALLOWED_HOSTS settings, must be valid domains separated by ,. default: * (not recommended for production);
- **LANGUAGE_CODE**: Django language code, default: en-us;
- **USE_TZ**: Force Django to use time-zone-aware datetime objects internally, defaults to false;
- **TIME_ZONE**: time zone, defaults to UTC;
- **DEBUG**: enables Django Debug mode, not recommended for production defaults to False;

### How to create a Superuser

#### Method 1 Environment Variables on first run.

If these variables are set on the first run it will trigger the creation of a superuser after the database is ready.

- **SUPER_USER**: Username of the django superuser (only used if no previous database is found);
  - **SUPER_PASS**: Password of the django superuser (optional, one will be generated if not found);
  - **SUPER_EMAIL**: Email of the django superuser (optional);

#### Method 2 Python Shell

At any moment after the database is ready, you can create a new superuser by running and following the prompts:

```docker exec -it {container_name} python manage.py createsuperuser```

### Upgrade application and database

If `AUTO_MIGRATE` is not set you can update by running:

```docker exec -it {container_name} python manage.py migrate```

### _Serving Static Files_

When behind a reverse-proxy/http server compatible `uwsgi` protocol the static files are located at `/var/www/etesync/static`, files will be copied if missing on start.
