#!/bin/sh -eu

# https://github.com/bgruening/docker-ipython-notebook/blob/master/monitor_traffic.sh
if [ -n ${MONITOR_TRAFFIC+x} ] ; then
    if [ "$MONITOR_TRAFFIC" != "false" ] ; then
        echo "--- Monitoring Traffic ---"
        while true; do
            sleep 60
            if [ `netstat -t | grep -v CLOSE_WAIT | grep ':7474' | wc -l` -lt 1 ]
            then
                pkill -f 'java'
            fi
        done
    fi
else
    echo "--- Not Monitoring Traffic ---"
fi
