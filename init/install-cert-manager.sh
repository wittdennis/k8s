#!/bin/bash

VERSION="v1.11.1"

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade -i cert-manager jetstack/cert-manager \
    -n cert-manager \
    --create-namespace \
    --version ${VERSION} \
    --set installCRDs=true \
    --set prometheus.enabled=true \
    --set webhook.hostNetwork=true \
    --set webhook.securePort=10260