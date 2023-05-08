#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

DASHBOARD_VERSION="2.0.7"
INGRESS_PATH="${SCRIPT_PATH}/dashboard/ingress.yaml"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v${DASHBOARD_VERSION}/aio/deploy/recommended.yaml

sed -i "s/\$DOMAIN/${DOMAIN_NAME}/g" ${INGRESS_PATH}
kubectl apply -f ${INGRESS_PATH}

yq -i '.spec.tls[0].hosts[0] = "dashboard.$DOMAIN" |
       .spec.rules[0].host = "dashboard.$DOMAIN"' ${INGRESS_PATH}