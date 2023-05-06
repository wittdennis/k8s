#!/bin/bash

set -e

VERSION="v1.11.1"
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade -i cert-manager jetstack/cert-manager \
    -n cert-manager \
    --create-namespace \
    --version ${VERSION} \
    --set installCRDs=true \
    --set prometheus.enabled=true \
    --set prometheus.servicemonitor.enabled=true \
    --set webhook.hostNetwork=true \
    --set webhook.securePort=10260

# Set secrets for clusterissuer
yq -i ".spec.acme.email = \"${ACME_REGISTRATION_EMAIL}\"" ${SCRIPT_PATH}/cert-manager/letsencrypt-clusterissuer.yaml
kubectl apply -f ${SCRIPT_PATH}/cert-manager/letsencrypt-clusterissuer.yaml

# reset secret
yq -i '.spec.acme.email = "$ACME_REGISTRATION_EMAIL"' ${SCRIPT_PATH}/cert-manager/letsencrypt-clusterissuer.yaml