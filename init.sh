#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

if test -f ${SCRIPT_PATH}/secrets.sh; then
    source ${SCRIPT_PATH}/secrets.sh
fi

. ${SCRIPT_PATH}/init/install-cert-manager.sh
kubectl apply -f ${SCRIPT_PATH}/init/lb-service.yaml
bash ${SCRIPT_PATH}/init/install-ingress-nginx.sh
bash ${SCRIPT_PATH}/init/install-monitoring-stack.sh