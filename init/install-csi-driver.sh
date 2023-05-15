#!/bin/bash

set -e

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")
CSI_DRIVER_VERSION="2.3.2"

kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v${CSI_DRIVER_VERSION}/deploy/kubernetes/hcloud-csi.yml
kubectl apply -f ${SCRIPT_PATH}/hcloud-csi-driver/serviceMonitor.yaml