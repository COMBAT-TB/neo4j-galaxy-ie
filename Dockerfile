FROM nginx:1.15-alpine

RUN apk update \
	&& apk upgrade \
	&& apk add --update --no-cache --quiet lsof net-tools wget bash curl openjdk8 shadow \
	&& mkdir /data

ENV GOSU_VERSION 1.10
RUN set -ex; \
	\
	apk add --no-cache --virtual .gosu-deps \
	dpkg \
	gnupg \
	openssl \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
	# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	chmod +x /usr/local/bin/gosu; \
	# verify that the binary works
	gosu nobody true; \
	\
	apk del .gosu-deps

ENV NEO4J_VERSION 3.1.9
ENV NEO4J_EDITION community
ENV NEO4J_SHA256 57f0b456d32d031e13b275445c24260fee4252d44b4e535ffc2e8f809ab854bd
ENV NEO4J_DOWNLOAD_ROOT http://dist.neo4j.org
ENV NEO4J_TARBALL neo4j-$NEO4J_EDITION-$NEO4J_VERSION-unix.tar.gz
ENV NEO4J_URI $NEO4J_DOWNLOAD_ROOT/$NEO4J_TARBALL
ENV NEO4J_AUTH none
# setting "dbms.connector.bolt.enabled" "false"
# setting "dbms.connector.https.enabled" "false"

ENV NEO4J_dbms_connector_bolt_enabled false
ENV NEO4J_dbms_connector_https_enabled false

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


ENV NEO4J_dbms_allowFormatMigration=true \
	NEO4J_dbms_unmanaged__extension__classes='extension.web=/guides' \
	NEO4J_org_neo4j_server_guide_directory='data/guides' \
	NEO4J_dbms_security_procedures_unrestricted='apoc.\\\*' \
	NEO4J_dbms_connectors_defaultAdvertisedAddress='0.0.0.0' \
	ENABLE_BOLT=true \
	MONITOR_TRAFFIC=true


COPY plugins/apoc-3.1.3.7-all.jar plugins/

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY run_neo4j.sh /run_neo4j.sh
COPY set_neo4j_settings.sh /set_neo4j_settings.sh
COPY monitor_traffic.sh /monitor_traffic.sh

COPY nginx.conf /etc/nginx/

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["neo4j"]
