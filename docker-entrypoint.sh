#!/bin/sh -eu

NEO4JDB_PATH=/data/neo4jdb
export NEO4JDB_PATH

if [ "$1" == "neo4j" ]; then
    if [ "${USER_UID:=none}" = "none" -o "${USER_GID:=none}" = "none" ] ; then
        echo "You need to set the USER_UID and USER_GID environment variables to use this container." >&2
        exit 1
    fi

    USER_GROUP=$(getent group $USER_GID | cut -d: -f1)
    if [ -z "$USER_GROUP" ] ; then
        USER_GROUP=neo4j
        addgroup -S -g $USER_GID $USER_GROUP
        echo "Added $USER_GID to $USER_GROUP"
    fi
    USER_USER=$(getent passwd $USER_UID | cut -d: -f1)
    if [ -z "$USER_USER" ] ; then
        USER_USER=neo4j
        adduser -u $USER_UID -S -g "$USER_GROUP nginx" $USER_USER
        usermod -aG root $USER_USER
    fi
    chown -R $USER_UID:$USER_GID /opt /data /var /dev
    EXISTING_UID=$(stat -c '%u' /data)
    EXISTING_GID=$(stat -c '%g' /data)
    echo "/opt /data $EXISTING_UID $EXISTING_GID"
    if [ $(stat -c '%u' /data) -ne $USER_UID -o $(stat -c '%g' /data) -ne $USER_GID ] ; then
        EXISTING_UID=$(stat -c '%u' /data)
        EXISTING_GID=$(stat -c '%g' /data)
        echo "The /data volume must be owned by user ID $USER_UID and group ID $USER_GID, instead it is owned by ${EXISTING_UID}: ${EXISTING_GID}" >&2
        exit 1
    fi
    if [ ! -d $NEO4JDB_PATH ] ; then
        gosu $USER_UID:$USER_GID cp -r /opt/neo4j/data $NEO4JDB_PATH
        echo "Initialising new database in $NEO4JDB_PATH"
        # echo "There is no database in $NEO4JDB_PATH, will exit." >&2
        # exit 1
    fi
    # Let's start nginx
    echo "Starting nginx..."
    nginx -g "daemon on;"
    # set some settings in the neo4j install dir
    /set_neo4j_settings.sh

    rm -rf /opt/neo4j/data
    ln -s $NEO4JDB_PATH /opt/neo4j/data
    # Launch traffic monitor which will automatically kill the container if
    # traffic stops - it waits 60 seconds before checking for an open
    # connection so this is safe
    /monitor_traffic.sh &

    gosu $USER_UID /run_neo4j.sh
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
