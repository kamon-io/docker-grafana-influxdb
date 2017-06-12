#!/bin/bash

set -m

CONFIG_FILE="/etc/grafana/config.ini"

echo "=> Starting Grafana ..."
exec /src/grafana/bin/grafana-server --homepath /src/grafana --config ${CONFIG_FILE}
