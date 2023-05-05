#!/bin/bash

SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

BIN_PATH=$SCRIPT_PATH/monitoring/tmp/bin

# install dependencies
export GOBIN=$BIN_PATH
go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
go install github.com/brancz/gojsontoyaml@latest
go install github.com/google/go-jsonnet/cmd/jsonnet@latest

pushd $SCRIPT_PATH/monitoring

$BIN_PATH/jb update
bash build.sh monitoring.jsonnet

popd

kubectl apply --server-side -f $SCRIPT_PATH/monitoring/manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
kubectl apply --server-side -f $SCRIPT_PATH/monitoring/manifests