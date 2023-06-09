#!/usr/bin/env bash

# This script uses arg $1 (name of *.jsonnet file to use) to generate the manifests/*.yaml files.

set -e
set -x
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

# Make sure to use project tooling
PATH="$(pwd)/tmp/bin:${PATH}"

SNITCH_URL=${SNITCH_URL}
PAGERDUTY_INTEGRATION_KEY=${PAGERDUTY_INTEGRATION_KEY}
GRAFANA_ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&?@' </dev/urandom | head -c 20  ; echo)

yq -i ".receivers[0].pagerduty_configs[0].routing_key = \"${PAGERDUTY_INTEGRATION_KEY}\" |
         .receivers[1].webhook_configs[0].url = \"${SNITCH_URL}\"" alertmanager-config.yaml
sed -i "s/\$DOMAIN/${DOMAIN_NAME}/g" ${1-monitoring.jsonnet}
sed -i "s/\$GRAFANA_ADMIN_PASSWORD/${GRAFANA_ADMIN_PASSWORD}/g" ${1-monitoring.jsonnet}
sed -i "s/\$GITHUB_APP_CLIENT_ID/${GRAFANA_OAUTH_CLIENT_ID}/g" ${1-monitoring.jsonnet}
sed -i "s/\$GITHUB_APP_CLIENT_SECRET/${GRAFANA_OAUTH_CLIENT_SECRET}/g" ${1-monitoring.jsonnet}
sed -i "s/\$GITHUB_ORG/${GITHUB_ORG}/g" ${1-monitoring.jsonnet}

# Make sure to start with a clean 'manifests' dir
rm -rf manifests
mkdir -p manifests/setup

# Calling gojsontoyaml is optional, but we would like to generate yaml, not json
jsonnet -J vendor -m manifests "${1-monitoring.jsonnet}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}

# Make sure to remove json files
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization

yq -i '.receivers[0].pagerduty_configs[0].routing_key = "$INTEGRATION_KEY" |
         .receivers[1].webhook_configs[0].url = "$SNITCH_URL"' alertmanager-config.yaml
sed -i "s/${DOMAIN_NAME}/\$DOMAIN/g" ${1-monitoring.jsonnet}
sed -i "s/${GRAFANA_ADMIN_PASSWORD}/\$GRAFANA_ADMIN_PASSWORD/g" ${1-monitoring.jsonnet}
sed -i "s/${GRAFANA_OAUTH_CLIENT_ID}/\$GITHUB_APP_CLIENT_ID/g" ${1-monitoring.jsonnet}
sed -i "s/${GRAFANA_OAUTH_CLIENT_SECRET}/\$GITHUB_APP_CLIENT_SECRET/g" ${1-monitoring.jsonnet}
sed -i "s/${GITHUB_ORG}/\$GITHUB_ORG/g" ${1-monitoring.jsonnet}