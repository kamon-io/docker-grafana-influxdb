#!/bin/bash

set -e

if [ ! -f "/.grafana_configured" ]; then
    /set_grafana.sh
fi

if [ ! -f "/.influxdb_configured" ]; then
    /set_influxdb.sh
fi
exit 0
