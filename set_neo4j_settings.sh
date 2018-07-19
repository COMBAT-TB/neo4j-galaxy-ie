#!/bin/sh -eu

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

if [ "${NEO4J_AUTH:-}" == "none" ]; then
    setting "dbms.security.auth_enabled" "false"
fi
if [ "${ENABLE_BOLT:-}" == "true" ]; then
    setting "dbms.connector.bolt.enabled" "true"
else
    setting "dbms.connector.bolt.enabled" "false"
fi
setting "dbms.connector.https.enabled" "false"
setting "dbms.connectors.default_listen_address" "0.0.0.0"
setting "dbms.connector.http.listen_address" "0.0.0.0:17474"
# setting "dbms.connector.https.listen_address" "0.0.0.0:7473"
setting "dbms.connector.bolt.listen_address" "0.0.0.0:17687"
setting "dbms.mode" "${NEO4J_dbms_mode:-}"
setting "dbms.directories.data" "${NEO4JDB_PATH}"
setting "dbms.connectors.default_advertised_address" "${NEO4J_dbms_connectors_defaultAdvertisedAddress:-}"
setting "ha.server_id" "${NEO4J_ha_serverId:-}"
setting "ha.host.data" "${NEO4J_ha_host_data:-}"
setting "ha.host.coordination" "${NEO4J_ha_host_coordination:-}"
setting "ha.initial_hosts" "${NEO4J_ha_initialHosts:-}"
setting "causal_clustering.expected_core_cluster_size" "${NEO4J_causalClustering_expectedCoreClusterSize:-}"
setting "causal_clustering.initial_discovery_members" "${NEO4J_causalClustering_initialDiscoveryMembers:-}"
setting "causal_clustering.discovery_advertised_address" "${NEO4J_causalClustering_discoveryAdvertisedAddress:-$(hostname):5000}"
setting "causal_clustering.transaction_advertised_address" "${NEO4J_causalClustering_transactionAdvertisedAddress:-$(hostname):6000}"
setting "causal_clustering.raft_advertised_address" "${NEO4J_causalClustering_raftAdvertisedAddress:-$(hostname):7000}"

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
