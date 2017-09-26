FROM openjdk:8-jre
RUN apt-get update --quiet --quiet \
    && apt-get upgrade -y \
    && apt-get install --quiet --quiet --no-install-recommends lsof net-tools \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /data

ENV GOSU_VERSION 1.7
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apt-get purge -y --auto-remove wget

ENV NEO4J_VERSION 3.2.3
ENV NEO4J_EDITION community
ENV NEO4J_DOWNLOAD_SHA256 65e1de8a025eae4ba42ad3947b7ecbf758a11cf41f266e8e47a83cd93c1d83d2
ENV NEO4J_DOWNLOAD_ROOT http://dist.neo4j.org
ENV NEO4J_TARBALL neo4j-$NEO4J_EDITION-$NEO4J_VERSION-unix.tar.gz
ENV NEO4J_URI $NEO4J_DOWNLOAD_ROOT/$NEO4J_TARBALL
ENV NEO4J_AUTH none

# These environment variables are passed from Galaxy to the container
# and help you enable connectivity to Galaxy from within the container.
# This means your user can import/export data from/to Galaxy.
ENV DEBIAN_FRONTEND=noninteractive \
    API_KEY=none \
    DEBUG=false \
    PROXY_PREFIX=none \
    GALAXY_URL=none \
    GALAXY_WEB_PORT=10000 \
    HISTORY_ID=none \
    REMOTE_HOST=none

WORKDIR /opt

RUN curl --fail --show-error --location --output neo4j.tar.gz $NEO4J_URI \
    && echo "$NEO4J_DOWNLOAD_SHA256 neo4j.tar.gz" | sha256sum --check --quiet - \
    && tar --extract --file neo4j.tar.gz --directory . \
    && mv neo4j-* neo4j \
    && rm neo4j.tar.gz

VOLUME /import

VOLUME /data

WORKDIR /opt/neo4j
ENV NEO4J_dbms_allowFormatMigration true
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY run_neo4j.sh /run_neo4j.sh
COPY set_neo4j_settings.sh /set_neo4j_settings.sh
COPY monitor_traffic.sh /monitor_traffic.sh

EXPOSE 7474 7687

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["neo4j"]
