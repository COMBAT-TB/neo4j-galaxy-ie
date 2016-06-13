#!/bin/bash -eu

[ -f "${EXTENSION_SCRIPT:-}" ] && . ${EXTENSION_SCRIPT}

if [ "${NEO4J_AUTH:-}" == "none" ]; then
    setting "dbms.security.auth_enabled" "false" neo4j-server.properties
elif [[ "${NEO4J_AUTH:-}" == neo4j/* ]]; then
    password="${NEO4J_AUTH#neo4j/}"
    bin/neo4j start || \
        (cat data/log/console.log && echo "Neo4j failed to start" && exit 1)
    echo "GOT HERE"
    if ! curl --fail --silent --user "neo4j:${password}" http://localhost:7474/db/data/ >/dev/null ; then
        curl --fail --silent --show-error --user neo4j:neo4j \
            --data '{"password": "'"${password}"'"}' \
            --header 'Content-Type: application/json' \
            http://localhost:7474/user/neo4j/password
    fi
    echo "PASSWORD SET"
    bin/neo4j stop
    echo "SHUTDOWN"
elif [ -n "${NEO4J_AUTH:-}" ]; then
    echo "Invalid value for NEO4J_AUTH: '${NEO4J_AUTH}'"
    exit 1
fi

echo "STARTING DB"
exec bin/neo4j console
