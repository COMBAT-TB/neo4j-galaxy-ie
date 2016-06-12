#!/bin/bash

# https://github.com/bgruening/docker-ipython-notebook/blob/master/monitor_traffic.sh
if [ "$NEO4J_MONITOR_TRAFFIC" != "false" ] ; then
    echo "--- Monitoring Traffic ---"
    while true; do
        sleep 60
        if [ `netstat -t | grep ESTABLISHED | grep ':7474' | wc -l` -lt 1 ]
        then
            pkill -f 'java'
        fi
    done
else
    echo "--- Not Monitoring Traffic ---"
fi
