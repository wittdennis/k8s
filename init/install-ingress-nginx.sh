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

kubectl delete -n ingress-nginx secret oauth2-proxy --ignore-not-found=true
kubectl create -n ingress-nginx secret generic oauth2-proxy \
                    --from-literal=client.id=${OAUTH_CLIENT_ID} \
                    --from-literal=client.secret=${OAUTH_CLIENT_SECRET} \
                    --from-literal=cookie.secret=${OAUTH_COOKIE_SECRET} 

sed -i "s/\$DOMAIN/${DOMAIN_NAME}/g" ${SCRIPT_PATH}/ingress-nginx/oauth2-proxy.yaml
sed -i "s/\$GITHUB_ORG/${GITHUB_ORG}/g" ${SCRIPT_PATH}/ingress-nginx/oauth2-proxy.yaml
kubectl apply -f ${SCRIPT_PATH}/ingress-nginx/oauth2-proxy.yaml
sed -i "s/${DOMAIN_NAME}/\$DOMAIN/g" ${SCRIPT_PATH}/ingress-nginx/oauth2-proxy.yaml
sed -i "s/${GITHUB_ORG}/\$GITHUB_ORG/g" ${SCRIPT_PATH}/ingress-nginx/oauth2-proxy.yaml