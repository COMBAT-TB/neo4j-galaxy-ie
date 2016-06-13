#!/bin/bash -eu

setting() {
    setting="${1}"
    value="${2}"
    file="${3}"
    if [ -n "${value}" ]; then
        sed --in-place "s|.*${setting}=.*|${setting}=${value}|" conf/"${file}"
    fi
}

cd ${NEO4J_INSTALL_DIR:=/opt/neo4j}

if [ "${NEO4J_AUTH:-}" == "none" ]; then
    setting "dbms.security.auth_enabled" "false" neo4j-server.properties
fi

setting "keep_logical_logs" "${NEO4J_KEEP_LOGICAL_LOGS:-100M size}" neo4j.properties
setting "dbms.pagecache.memory" "${NEO4J_CACHE_MEMORY:-512M}" neo4j.properties
setting "wrapper.java.additional=-Dneo4j.ext.udc.source" "${NEO4J_UDC_SOURCE:-docker}" neo4j-wrapper.conf
setting "wrapper.java.initmemory" "${NEO4J_HEAP_MEMORY:-512}" neo4j-wrapper.conf
setting "wrapper.java.maxmemory" "${NEO4J_HEAP_MEMORY:-512}" neo4j-wrapper.conf
setting "org.neo4j.server.thirdparty_jaxrs_classes" "${NEO4J_THIRDPARTY_JAXRS_CLASSES:-}" neo4j-server.properties
setting "allow_store_upgrade" "${NEO4J_ALLOW_STORE_UPGRADE:-}" neo4j.properties

setting "org.neo4j.server.webserver.address" "0.0.0.0" neo4j-server.properties
setting "org.neo4j.server.database.mode" "${NEO4J_DATABASE_MODE:-}" neo4j-server.properties
setting "org.neo4j.server.database.location" ${NEO4JDB_PATH} neo4j-server.properties
setting "org.neo4j.server.http.log.config" ${NEO4JDB_PATH}/log neo4j-server.properties
setting "ha.server_id" "${NEO4J_SERVER_ID:-}" neo4j.properties
setting "ha.server" "${NEO4J_HA_ADDRESS:-}:6001" neo4j.properties
setting "ha.cluster_server" "${NEO4J_HA_ADDRESS:-}:5001" neo4j.properties
setting "ha.initial_hosts" "${NEO4J_INITIAL_HOSTS:-}" neo4j.properties

if [ -d /conf ]; then
    find /conf -type f -exec cp {} conf \;
fi

if [ -d /ssl ]; then
    num_certs=$(ls /ssl/*.cert 2>/dev/null | wc -l)
    num_keys=$(ls /ssl/*.key 2>/dev/null | wc -l)
    if [ $num_certs == "1" -a $num_keys == "1" ]; then
        cert=$(ls /ssl/*.cert)
        key=$(ls /ssl/*.key)
        setting "dbms.security.tls_certificate_file" $cert neo4j-server.properties
        setting "dbms.security.tls_key_file" $key neo4j-server.properties
    else
        echo "You must provide exactly one *.cert and exactly one *.key in /ssl."
        exit 1
    fi
else
    setting "dbms.security.tls_certificate_file" ${NEO4JDB_PATH}/ssl/snakeoil.cert neo4j-server.properties
    setting "dbms.security.tls_key_file" ${NEO4JDB_PATH}/ssl/snakeoil.key neo4j-server.properties
fi

if [ -d /plugins ]; then
    find /plugins -type f -exec cp {} plugins \;
fi
