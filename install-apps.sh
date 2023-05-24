#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

install_app() {
    local APP_PATH="$1"
    local SHOULD_INSTALL=$2

    if [ ${SHOULD_INSTALL} = 1 ]; then
        echo "Installing: ${APP_PATH}"
        bash ${APP_PATH}
    else
        echo "Skipping: ${APP_PATH}"
    fi
}

install_app ${SCRIPT_PATH}/apps/install-postgres-operator.sh 0
install_app ${SCRIPT_PATH}/apps/install-mariadb-operator.sh 1

