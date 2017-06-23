FROM openjdk:8-jre-alpine

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache --quiet lsof net-tools wget bash \
    && mkdir /data

ENV GOSU_VERSION="1.7" \
	GOSU_DOWNLOAD_URL="https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" \
	GOSU_DOWNLOAD_SIG="https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64.asc" \
	GOSU_DOWNLOAD_KEY="0x036A9C25BF357DD4"

#   https://github.com/tianon/gosu/releases
RUN buildDeps='curl gnupg' HOME='/root' \
	&& set -x \
	&& apk add --update $buildDeps \
	&& gpg-agent --daemon \
	&& gpg --keyserver pgp.mit.edu --recv-keys $GOSU_DOWNLOAD_KEY \
	&& echo "trusted-key $GOSU_DOWNLOAD_KEY" >> /root/.gnupg/gpg.conf \
	&& curl -sSL "$GOSU_DOWNLOAD_URL" > gosu-amd64 \
	&& curl -sSL "$GOSU_DOWNLOAD_SIG" > gosu-amd64.asc \
	&& gpg --verify gosu-amd64.asc \
	&& rm -f gosu-amd64.asc \
	&& mv gosu-amd64 /usr/bin/gosu \
	&& chmod +x /usr/bin/gosu \
	&& rm -rf /root/.gnupg \
	&& rm -rf /var/cache/apk/*

ENV NEO4J_VERSION 3.1.5
ENV NEO4J_EDITION community
ENV NEO4J_SHA256 47317a5a60f72de3d1b4fae4693b5f15514838ff3650bf8f2a965d3ba117dfc2
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

RUN curl --fail --show-error --location --output ${NEO4J_TARBALL} ${NEO4J_URI}
RUN echo "${NEO4J_SHA256}  ${NEO4J_TARBALL}" | sha256sum -csw -
RUN tar --extract --file ${NEO4J_TARBALL} --directory . \
    && mv neo4j-$NEO4J_EDITION-$NEO4J_VERSION neo4j \
    && rm ${NEO4J_TARBALL}

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
