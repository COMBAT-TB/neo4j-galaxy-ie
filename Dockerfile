FROM openjdk:8-jre-alpine
LABEL maintainer="thoba@sanbi.ac.za"

RUN addgroup -S neo4j && adduser -S -H -h /var/lib/neo4j -G neo4j neo4j

ENV NEO4J_SHA256=57ae9e512705b7c2f09067b6bc1c4d1727334e0081d01ce6bded65f0eb7cf7c1 \
	NEO4J_TARBALL=neo4j-community-3.4.1-unix.tar.gz \
	NEO4J_EDITION=community
ARG NEO4J_URI=http://dist.neo4j.org/neo4j-community-3.4.1-unix.tar.gz

# COPY ./local-package/* /tmp/

RUN apk add --no-cache --quiet \
	bash \
	curl \
	tini \
	su-exec \
	&& curl --fail --silent --show-error --location --remote-name ${NEO4J_URI} \
	&& echo "${NEO4J_SHA256}  ${NEO4J_TARBALL}" | sha256sum -csw - \
	&& tar --extract --file ${NEO4J_TARBALL} --directory /var/lib \
	&& mv /var/lib/neo4j-* /var/lib/neo4j \
	&& rm ${NEO4J_TARBALL} \
	&& mv /var/lib/neo4j/data /data \
	&& chown -R neo4j:neo4j /data \
	&& chmod -R 777 /data \
	&& chown -R neo4j:neo4j /var/lib/neo4j \
	&& chmod -R 777 /var/lib/neo4j \
	&& ln -s /data /var/lib/neo4j/data \
	&& apk del curl

ENV PATH /var/lib/neo4j/bin:$PATH

WORKDIR /var/lib/neo4j

VOLUME /data
VOLUME /import

COPY plugins/*.jar plugins/
COPY guides/*.html guides/
COPY *.sh /

ENV NEO4J_dbms_unmanaged__extension__classes='extension.web=/guides' \
	NEO4J_org_neo4j_server_guide_directory='guides' \
	NEO4J_dbms_allow__upgrade=true \
	NEO4J_dbms_allow__format__migration=true \
	# NEO4J_dbms_read__only=true \
	NEO4J_dbms_security_procedures_unrestricted='apoc.\\\*' \
	NEO4J_dbms_directories_data='/data/neo4jdb'
RUN echo 'browser.remote_content_hostname_whitelist=*' >> conf/neo4j.conf

EXPOSE 7474 7473 7687

ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
CMD ["neo4j"]
