FROM python:3.8.5-alpine

ARG TAG='master'

ENV BASE_DIR /etesync
ENV DATA_DIR /data
ENV STATIC_DIR /var/www/etesync

ENV SECRET_FILE $BASE_DIR/secret.txt
ENV ETESYNC_DB_PATH $DATA_DIR/db.sqlite3

ARG CERT_DIR=/certs
ENV X509_CRT $CERT_DIR/crt.pem
ENV X509_KEY $CERT_DIR/key.pem

ENV PUID 1000
ENV PGID 1000
ENV PORT 3735
ENV SERVER="http"

WORKDIR $BASE_DIR

COPY --chown=1000:1000 server /etesync
COPY --chown=1000:1000 context /

RUN set -e && \
    addgroup -g $PGID -S etesync && \
    adduser -h $BASE_DIR -s /bin/sh -D -H -G etesync -u $PUID etesync && \
    apk add --no-cache openssl libressl mailcap libpq && \
    apk add --no-cache --virtual .build-deps coreutils gcc make linux-headers libc-dev libressl-dev postgresql-dev && \
    pip install -r $BASE_DIR/requirements.txt uwsgi psycopg2-binary && \
    apk del .build-deps && \
    mkdir -p $DATA_DIR $CERT_DIR $STATIC_DIR && \
    $BASE_DIR/manage.py collectstatic && \
    mv $BASE_DIR/static $STATIC_DIR/ && \
    ln -s $STATIC_DIR/static $BASE_DIR/static && \
    rm $BASE_DIR/requirements.txt $SECRET_FILE && \
    chown -h etesync:etesync $BASE_DIR/static && \
    chown -R etesync:etesync $STATIC_DIR $DATA_DIR $BASE_DIR && \
    chmod -R a=rX $STATIC_DIR

VOLUME $DATA_DIR

EXPOSE 3735

ENTRYPOINT ["/entrypoint.sh"]