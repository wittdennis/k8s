#!/bin/bash

set -e

OPERATOR_VERSION="1.10.0"
UI_VERSION="1.10.0"

# add repo for postgres-operator
helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui

# install the postgres-operator
helm upgrade --install -n operators --create-namespace --version ${OPERATOR_VERSION} postgres-operator postgres-operator-charts/postgres-operator
helm upgrade --install -n operators --create-namespace --version ${UI_VERSION} postgres-operator-ui postgres-operator-ui-charts/postgres-operator-ui