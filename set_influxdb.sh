#!/bin/bash

set -m
CONFIG_FILE="/etc/influxdb/config.toml"

API_URL="http://localhost:8086"

#if [ -n "${FORCE_HOSTNAME}" ]; then
#	if [ "${FORCE_HOSTNAME}" == "auto" ]; then
#		#set hostname with IPv4 eth0
#		HOSTIPNAME=$(ip a show dev eth0 | grep inet | grep eth0 | sed -e 's/^.*inet.//g' -e 's/\/.*$//g')
#		/usr/bin/perl -p -i -e "s/^# hostname.*$/hostname = \"${HOSTIPNAME}\"/g" ${CONFIG_FILE}
#	else
#		/usr/bin/perl -p -i -e "s/^# hostname.*$/hostname = \"${FORCE_HOSTNAME}\"/g" ${CONFIG_FILE}
#	fi
#fi
#
#if [ -n "${SEEDS}" ]; then
#	/usr/bin/perl -p -i -e "s/^# seed-servers.*$/seed-servers = [${SEEDS}]/g" ${CONFIG_FILE}
#fi
#
#if [ -n "${REPLI_FACTOR}" ]; then
#	/usr/bin/perl -p -i -e "s/replication-factor = 1/replication-factor = ${REPLI_FACTOR}/g" ${CONFIG_FILE}
#fi
#
#if [ "${PRE_CREATE_DB}" == "**None**" ]; then
#    unset PRE_CREATE_DB
#fi
#
#if [ "${SSL_CERT}" == "**None**" ]; then
#    unset SSL_CERT
#fi
#
#API_URL="http://localhost:8086"
#if [ -n "${SSL_CERT}" ]; then 
#    echo "=> Found ssl cert file, using ssl api instead"
#    echo "=> Listening on port 8084(https api), disabling port 8086(http api)"
#    echo -e "${SSL_CERT}" > /cert.pem
#    sed -i -r -e 's/^# ssl-/ssl-/g' -e 's/^port *= * 8086/# port = 8086/' ${CONFIG_FILE}
#    API_URL="https://localhost:8084"
#fi

echo "=> About to create the following database: ${PRE_CREATE_DB}"
if [ -f "/.influxdb_configured" ]; then
    echo "=> Database had been created before, skipping ..."
else
    echo "=> Starting InfluxDB ..."
    exec /usr/bin/influxdb -config=${CONFIG_FILE} &
    arr=$(echo ${PRE_CREATE_DB} | tr ";" "\n")

    #wait for the startup of influxdb
    RET=1
    while [[ RET -ne 0 ]]; do
        echo "=> Waiting for confirmation of InfluxDB service startup ..."
        sleep 3 
        curl -k ${API_URL}/ping 2> /dev/null
        RET=$?
    done
    echo ""

    for x in $arr
    do
        echo "=> Creating database: ${x}"
        curl -s -k -X POST -d "{\"name\":\"${x}\"}" $(echo ${API_URL}'/db?u=root&p=root')
    done
    echo ""
    
    echo "=> Creating User for database: data"
    curl -s -k -X POST -d "{\"name\":\"${INFLUXDB_DATA_USER}\",\"password\":\"${INFLUXDB_DATA_PW}\"}" $(echo ${API_URL}'/db/data/users?u=root&p=root')
    echo "=> Creating User for database: grafana"
    curl -s -k -X POST -d "{\"name\":\"${INFLUXDB_GRAFANA_USER}\",\"password\":\"${INFLUXDB_GRAFANA_PW}\"}" $(echo ${API_URL}'/db/grafana/users?u=root&p=root')
    echo ""
    
    echo "=> Changing Password for User: root"
    curl -s -k -X POST -d "{\"password\":\"${ROOT_PW}\"}" $(echo ${API_URL}'/cluster_admins/root?u=root&p=root')
    echo ""

    touch "/.influxdb_configured"
    exit 0
fi

exit 0
