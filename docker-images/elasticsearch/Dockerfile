FROM arm64v8/alpine:3.7

# See also...
# https://hub.docker.com/u/arm64v8/
# https://github.com/elastic/elasticsearch-alpine-base/blob/master/build/elasticsearch-alpine-base/Dockerfile

RUN set -x \
 && apk add --no-cache --update \
            bash \
            curl \
            openjdk8 \
            openjdk8-jre \
            openssl \
 && curl -o /usr/local/bin/gosu -sSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" \
 && chmod +x /usr/local/bin/gosu \
 && mkdir -p /packages

ENV ELASTICSEARCH_VERSION="6.2.1"

COPY packages/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz /packages/
COPY docker-entrypoint.sh /

WORKDIR /packages

RUN set -x \
 && chmod +x /docker-entrypoint.sh \
 && pwd && env && ls -al \
 && tar -xzf elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
 && ls -alR . \
 && mv elasticsearch-${ELASTICSEARCH_VERSION} /usr/share/elasticsearch \
 && mkdir -p /usr/share/elasticsearch/data /usr/share/elasticsearch/logs /usr/share/elasticsearch/config/scripts \
 && adduser -DH -s /sbin/nologin -h /usr/share/elasticsearch elasticsearch \
 && chown -R elasticsearch:elasticsearch /usr/share/elasticsearch

ENV PATH /usr/share/elasticsearch/bin:$PATH

WORKDIR /usr/share/elasticsearch

VOLUME /usr/share/elasticsearch/data

EXPOSE 9200 9300
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["elasticsearch"]

