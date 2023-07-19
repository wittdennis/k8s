#!/bin/bash

set -e

VERSION="0.17.0"

helm repo add mariadb-operator https://mariadb-operator.github.io/mariadb-operator
helm upgrade --install -n operators --create-namespace --version ${VERSION} \
                            mariadb-operator mariadb-operator/mariadb-operator \
                            --set metrics.enabled=true \
                            --set webhook.certificate.certManager=true