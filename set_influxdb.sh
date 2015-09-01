#!/bin/bash

set -m
CONFIG_FILE="/etc/influxdb/influxdb.conf"
INFLUX_BIN="/opt/influxdb/versions/0.9.3/influx"
INFLUXD_BIN="/opt/influxdb/versions/0.9.3/influxd"

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

function query_endpoint() {
    curl -u "root:${ROOT_PW}" -s -k -G --data-urlencode "q=$1" "${API_URL}/query"; echo
}

echo "=> About to create the following database: ${PRE_CREATE_DB}"
if [ -f "/.influxdb_configured" ]; then
    echo "=> Database had been created before, skipping ..."
else
    echo "=> Starting InfluxDB ..."
    exec "$INFLUXD_BIN" -config=${CONFIG_FILE} -pidfile /var/run/influxdb/influxd.pid &
    arr=$(echo ${PRE_CREATE_DB} | tr ";" "\n")

    #wait for the startup of influxdb
    RET=1
    while [[ RET -ne 0 ]]; do
        echo "=> Waiting for confirmation of InfluxDB service startup ..."
        sleep 3 
        curl -k ${API_URL}/ping 2> /dev/null
        RET=$?
		ps ax
    done
    echo ""

	#create the root user
	$INFLUX_BIN -execute "create user root with password '${ROOT_PW}' with all privileges" || exit 1
	$INFLUX_BIN -username "root" -password "${ROOT_PW}" -execute "show users" || exit 1

    for x in $arr
    do
        echo "=> Creating database: ${x}"
        query_endpoint "create database ${x}"
    done
    echo ""
    
    echo "=> Creating User for database: data"
	query_endpoint "create user $INFLUXDB_DATA_USER with password '$INFLUXDB_DATA_PW'"

    echo "=> Granting User rights for database: data"
	query_endpoint "grant all on data to $INFLUXDB_DATA_USER"

    echo "=> Creating User for database: grafana"
	query_endpoint "create user $INFLUXDB_GRAFANA_USER with password '$INFLUXDB_GRAFANA_PW'"

    echo "=> Granting User rights for database: grafana"
	query_endpoint "grant all on grafana to $INFLUXDB_GRAFANA_USER"
    echo ""

    touch "/.influxdb_configured"
    exit 0
fi

exit 0
