#!/bin/bash

set -m

CONFIG_FILE="/etc/influxdb/influxdb.conf"

echo "=> Starting InfluxDB ..."
exec /usr/bin/influxdb -config=${CONFIG_FILE}
