#!/bin/bash

set -e

VERSION="4.6.1"
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx \
    -n ingress-nginx \
    --create-namespace \
    --version ${VERSION} \
    -f ${SCRIPT_PATH}/ingress-nginx/helm-values/default.yaml