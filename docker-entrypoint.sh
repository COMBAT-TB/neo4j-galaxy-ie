#!/bin/bash -eu

NEO4JDB_PATH=/data/neo4jdb
export NEO4JDB_PATH

if [ "$1" == "neo4j" ]; then
    if [ "${NEO4J_UID:=none}" = "none" -o "${NEO4J_GID:=none}" = "none" ] ; then
        echo "You need to set the NEO4J_UID and NEO4J_GID environment variables to use this container." >&2
        exit 1
    fi
    
    NEO4J_GROUP=$(getent group $NEO4J_GID | cut -d: -f1)
    if [ $? -ne 0 ] ; then
        NEO4J_GROUP=neo4j
        groupadd -g $NEO4J_GID $NEO4J_GROUP
    fi
    NEO4J_USER=$(getent passwd $NEO4J_UID | cut -d: -f1)
    if [ $? -ne 0 ] ; then
        NEO4J_USER=neo4j
        useradd -u $NEO4J_UID -g $NEO4J_GROUP $NEO4J_USER
    fi

    if [ $(stat -c '%u' /data) -ne $NEO4J_UID -o $(stat -c '%g' /data) -ne $NEO4J_GID ] ; then
        EXISTING_UID=$(stat -c '%u' /data)
        EXISTING_GID=$(stat -c '%g' /data)
        echo "The /data volume must be owned by user ID $NEO4J_UID and group ID $NEO4J_GID, instead it is owned by ${EXISTING_UID}: ${EXISTING_GID}" >&2
        exit 1
    fi
    if [ ! -d $NEO4JDB_PATH ] ; then
        gosu $NEO4J_UID:$NEO4J_GID cp -r /opt/neo4j/data $NEO4JDB_PATH
        echo "Initialising new database in $NEO$JDB_PATH"
        # echo "There is no database in $NEO4JDB_PATH, will exit." >&2
        # exit 1
    fi

    # set some settings in the neo4j install dir
    /set_neo4j_settings.sh

    rm -rf /opt/neo4j/data
    ln -s $NEO4JDB_PATH /opt/neo4j/data
    # Launch traffic monitor which will automatically kill the container if
    # traffic stops - it waits 60 seconds before checking for an open
    # connection so this is safe
    /monitor_traffic.sh &

    gosu $NEO4J_UID:$NEO4J_GID /run_neo4j.sh
elif [ "$1" == "dump-config" ]; then
    if [ -d /conf ]; then
        cp --recursive conf/* /conf
    else
        echo "You must provide a /conf volume"
        exit 1
    fi
else
    exec "$@"
fi
