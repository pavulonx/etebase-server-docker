FROM python:3.8.5-alpine

ARG TAG='master'

ENV BASE_DIR /etesync
ENV DATA_DIR /data
ENV STATIC_DIR /var/www/etesync

ENV SECRET_FILE $BASE_DIR/secret.txt
ENV ETESYNC_DB_PATH $DATA_DIR/db.sqlite3

ENV PUID 1000
ENV PGID 1000
ENV PORT 3735

WORKDIR $BASE_DIR

RUN set -e && \
    addgroup -g $PGID -S etesync && \
    adduser -h $BASE_DIR -s /bin/sh -D -H -G etesync -u $PUID etesync && \
    mkdir -p $DATA_DIR && \
    mkdir -p $STATIC_DIR && \
    apk add --no-cache openssl libressl mailcap libpq && \
    apk add --no-cache --virtual .build-deps git coreutils gcc make linux-headers libc-dev libressl-dev libffi-dev postgresql-dev && \
    git clone --depth=1 https://github.com/etesync/server.git $BASE_DIR && \
    pip install -r $BASE_DIR/requirements.txt daphne && \
    apk del .build-deps git && \
    $BASE_DIR/manage.py collectstatic && \
    mv $BASE_DIR/static $STATIC_DIR/ && \
    ln -s $STATIC_DIR/static $BASE_DIR/static && \
    rm $BASE_DIR/requirements.txt $SECRET_FILE && \
    chown -h etesync:etesync $BASE_DIR/static && \
    chown -R etesync:etesync $STATIC_DIR && \
    chmod -R a=rX $STATIC_DIR && \
    chown -R etesync:etesync $DATA_DIR && \
    chmod -R ug=rwX $DATA_DIR && \
    chown -R etesync:etesync $BASE_DIR && \
    chmod -R ug=rwX $BASE_DIR

COPY --chown=etesync:etesync etesync/etesync.ini /etesync
COPY entrypoint.sh /

# Fix permissions
RUN chown root:root /entrypoint.sh && \
    chmod a=rx /entrypoint.sh

VOLUME $DATA_DIR

EXPOSE $PORT

ENTRYPOINT ["/entrypoint.sh"]