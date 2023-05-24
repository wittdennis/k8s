#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

if test -f ${SCRIPT_PATH}/secrets.sh; then
    source ${SCRIPT_PATH}/secrets.sh
fi

bash ${SCRIPT_PATH}/init/install-monitoring-stack.sh
bash ${SCRIPT_PATH}/init/install-csi-driver.sh
bash ${SCRIPT_PATH}/init/install-cert-manager.sh
bash ${SCRIPT_PATH}/init/install-ingress-nginx.sh
bash ${SCRIPT_PATH}/init/install-dashboard.sh