FROM arm64v8/alpine:3.7

# See also...
# https://hub.docker.com/u/arm64v8/
# https://github.com/elastic/elasticsearch-alpine-base/blob/master/build/elasticsearch-alpine-base/Dockerfile

ENV ELASTICSEARCH_VERSION="6.2.1"
COPY packages/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz /packages/
COPY docker-entrypoint.sh /

RUN set -x \
 && apk add --no-cache --update \
            bash \
            curl \
            su-exec \
            openssl \
            coreutils \
            openjdk8-jre \
 && chmod +x /docker-entrypoint.sh \
 && cd /packages \
 && tar -xzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
 && ls -alR . \
 && mv elasticsearch-${ELASTICSEARCH_VERSION} /usr/share/elasticsearch \
 && cd /usr/share/elasticsearch \
 && rm -rf /packages \
 && mkdir -p data logs config/scripts \
 && adduser -DH -s /sbin/nologin -h /usr/share/elasticsearch elasticsearch \
 && chown -R elasticsearch:elasticsearch /usr/share/elasticsearch

ENV PATH /usr/share/elasticsearch/bin:$PATH

WORKDIR /usr/share/elasticsearch

VOLUME /usr/share/elasticsearch/data

EXPOSE 9200 9300

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "/usr/share/elasticsearch/bin/elasticsearch" ]

USER elasticsearch

