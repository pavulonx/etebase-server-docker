FROM python:3.8.5-alpine

ARG REPO='https://github.com/etesync/server.git'
ARG REPO_REF='master'

ARG BASE_DIR=/etebase
ARG DATA_DIR=/data
ARG STATIC_DIR=/var/www/etebase

ARG SECRET_FILE=$BASE_DIR/secret.txt

ENV PUID 1000
ENV PGID 1000
ENV PORT 3735

WORKDIR $BASE_DIR

RUN set -e && \
    groupadd -r -g $PGID etebase && \
	useradd -d $BASE_DIR -r -M -s /bin/sh -g $PGID -u $PUID etebase && \
    mkdir -p $DATA_DIR && \
    mkdir -p $STATIC_DIR

RUN set -e && \
    apk add --no-cache openssl libressl mailcap libpq && \
    apk add --no-cache --virtual .build-deps \
        git coreutils gcc make linux-headers libc-dev \
        libressl-dev libffi-dev postgresql-dev && \
    git clone --depth=1 -b $REPO_REF $REPO $BASE_DIR && \
    pip install -r $BASE_DIR/requirements.txt daphne && \
    apk del .build-deps

RUN set -e && \
    $BASE_DIR/manage.py collectstatic && \
    mv $BASE_DIR/static $STATIC_DIR/ && \
    ln -s $STATIC_DIR/static $BASE_DIR/static && \
    rm $BASE_DIR/requirements.txt $SECRET_FILE && \
    chown -h etebase:etebase $BASE_DIR/static && \
    chown -R etebase:etebase $STATIC_DIR && \
    chmod -R a=rX $STATIC_DIR && \
    chown -R etebase:etebase $DATA_DIR && \
    chmod -R ug=rwX $DATA_DIR && \
    chown -R etebase:etebase $BASE_DIR && \
    chmod -R ug=rwX $BASE_DIR

COPY --chown=etebase:etebase config_templates /etebase/config_templates

COPY entrypoint.sh /
RUN chmod a=rx /entrypoint.sh

VOLUME $DATA_DIR

EXPOSE $PORT

ENTRYPOINT ["/entrypoint.sh"]

USER etebase