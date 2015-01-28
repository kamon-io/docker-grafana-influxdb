#!/bin/bash

set -e

if [ ! -f "/.grafana_configured" ]; then
    /set_grafana.sh
fi

exit 0
