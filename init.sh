#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

. ${SCRIPT_PATH}/init/install-cert-manager.sh
kubectl apply -f ${SCRIPT_PATH}/init/lb-service.yaml
bash ${SCRIPT_PATH}/init/install-ingress-nginx.sh