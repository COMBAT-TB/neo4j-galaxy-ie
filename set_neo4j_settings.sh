#!/bin/bash -eu

# Env variable naming convention:
# - prefix NEO4J_
# - double underscore char '__' instead of single underscore '_' char in the setting name
# - underscore char '_' instead of dot '.' char in the setting name
# Example:
# NEO4J_dbms_tx__log_rotation_retention_policy env variable to set
#       dbms.tx_log.rotation.retention_policy setting

# Backward compatibility - map old hardcoded env variables into new naming convention
NEO4J_dbms_tx__log_rotation_retention_policy=${NEO4J_dbms_txLog_rotation_retentionPolicy:-}
NEO4J_wrapper_java_additional=${NEO4J_UDC_SOURCE:-}
NEO4J_dbms_memory_heap_initial__size=${NEO4J_dbms_memory_heap_maxSize:-}
NEO4J_dbms_memory_heap_max__size=${NEO4J_dbms_memory_heap_maxSize:-}
NEO4J_dbms_unmanaged__extension__classes=${NEO4J_dbms_unmanagedExtensionClasses:-}
NEO4J_dbms_allow__format__migration=${NEO4J_dbms_allowFormatMigration:-}
NEO4J_dbms_connectors_default__advertised__address=${NEO4J_dbms_connectors_defaultAdvertisedAddress:-}
NEO4J_ha_server__id=${NEO4J_ha_serverId:-}
NEO4J_ha_initial__hosts=${NEO4J_ha_initialHosts:-}
NEO4J_causal__clustering_expected__core__cluster__size=${NEO4J_causalClustering_expectedCoreClusterSize:-}
NEO4J_causal__clustering_initial__discovery__members=${NEO4J_causalClustering_initialDiscoveryMembers:-}
NEO4J_causal__clustering_discovery__listen__address=${NEO4J_causalClustering_discoveryListenAddress:-}
NEO4J_causal__clustering_discovery__advertised__address=${NEO4J_causalClustering_discoveryAdvertisedAddress:-}
NEO4J_causal__clustering_transaction__listen__address=${NEO4J_causalClustering_transactionListenAddress:-}
NEO4J_causal__clustering_transaction__advertised__address=${NEO4J_causalClustering_transactionAdvertisedAddress:-}
NEO4J_causal__clustering_raft__listen__address=${NEO4J_causalClustering_raftListenAddress:-}
NEO4J_causal__clustering_raft__advertised__address=${NEO4J_causalClustering_raftAdvertisedAddress:-}

# unset old hardcoded unsupported env variables
unset NEO4J_dbms_txLog_rotation_retentionPolicy NEO4J_UDC_SOURCE \
    NEO4J_dbms_memory_heap_maxSize NEO4J_dbms_memory_heap_maxSize \
    NEO4J_dbms_unmanagedExtensionClasses NEO4J_dbms_allowFormatMigration \
    NEO4J_dbms_connectors_defaultAdvertisedAddress NEO4J_ha_serverId \
    NEO4J_ha_initialHosts NEO4J_causalClustering_expectedCoreClusterSize \
    NEO4J_causalClustering_initialDiscoveryMembers \
    NEO4J_causalClustering_discoveryListenAddress \
    NEO4J_causalClustering_discoveryAdvertisedAddress \
    NEO4J_causalClustering_transactionListenAddress \
    NEO4J_causalClustering_transactionAdvertisedAddress \
    NEO4J_causalClustering_raftListenAddress \
    NEO4J_causalClustering_raftAdvertisedAddress

# Custom settings for dockerized neo4j
: ${NEO4J_dbms_directories_data:=/data/neo4jdb}
: ${NEO4J_dbms_allow__format__migration:=true}
: ${NEO4J_dbms_tx__log_rotation_retention_policy:=100M size}
: ${NEO4J_dbms_memory_pagecache_size:=512M}
: ${NEO4J_wrapper_java_additional:=-Dneo4j.ext.udc.source=docker}
: ${NEO4J_dbms_memory_heap_initial__size:=512M}
: ${NEO4J_dbms_memory_heap_max__size:=512M}
: ${NEO4J_dbms_connectors_default__listen__address:=0.0.0.0}
: ${NEO4J_dbms_connector_http_listen__address:=0.0.0.0:7474}
: ${NEO4J_ha_host_coordination:=$(hostname):5001}
: ${NEO4J_ha_host_data:=$(hostname):6001}
: ${NEO4J_causal__clustering_discovery__listen__address:=0.0.0.0:5000}
: ${NEO4J_causal__clustering_discovery__advertised__address:=$(hostname):5000}
: ${NEO4J_causal__clustering_transaction__listen__address:=0.0.0.0:6000}
: ${NEO4J_causal__clustering_transaction__advertised__address:=$(hostname):6000}
: ${NEO4J_causal__clustering_raft__listen__address:=0.0.0.0:7000}
: ${NEO4J_causal__clustering_raft__advertised__address:=$(hostname):7000}

if [ -d /conf ]; then
    find /conf -type f -exec cp {} conf \;
fi

if [ -d /ssl ]; then
    NEO4J_dbms_directories_certificates="/ssl"
fi

if [ -d /plugins ]; then
    NEO4J_dbms_directories_plugins="/plugins"
fi

if [ -d /logs ]; then
    NEO4J_dbms_directories_logs="/logs"
fi

if [ -d /import ]; then
    NEO4J_dbms_directories_import="/import"
fi

if [ -d /metrics ]; then
    NEO4J_dbms_directories_metrics="/metrics"
fi

# list env variables with prefix NEO4J_ and create settings from them
unset NEO4J_AUTH NEO4J_SHA256 NEO4J_TARBALL
for i in $( set | grep ^NEO4J_ | awk -F'=' '{print $1}' | sort -rn ); do
    setting=$(echo ${i} | sed 's|^NEO4J_||' | sed 's|_|.|g' | sed 's|\.\.|_|g')
    value=$(echo ${!i})
    if [[ -n ${value} ]]; then
        if grep -q -F "${setting}=" conf/neo4j.conf; then
            sed --in-place "s|.*${setting}=.*|${setting}=${value}|" conf/neo4j.conf
        else
            echo "${setting}=${value}" >> conf/neo4j.conf
        fi
    fi
done