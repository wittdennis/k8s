# Hetzner k8s

This project provides all resources to create a Kubernetes Cluster on [Hetzner Cloud](https://www.hetzner.com/cloud).

## Infrastructure Setup

Create a `terraform.tfvars` file in the directory `terraform`.

The file has to contain these values:

```terraform
hcloud_token = "<your_hcloud_token>"
```

## Cluster initialization

Create a `secrets.sh` file in the root directory.

The file has to contain these values:

```sh
#!/bin/bash

export PAGERDUTY_INTEGRATION_KEY="<your_pagerduty_integration_key>"
export SNITCH_URL="<your_deadmansnitch_snitch_url"
export ACME_REGISTRATION_EMAIL="<email_for_letsencrypt_registration>"
export DOMAIN_NAME="<domain_name_of_cluster>"
export OAUTH_CLIENT_ID="<github_oauth_app_client_id>"
export OAUTH_CLIENT_SECRET="<github_oauth_app_client_secret>"
export OAUTH_COOKIE_SECRET="<generated_base64encoded_oauth_cookie_secret>" # eg.: dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_'; echo
export GRAFANA_OAUTH_CLIENT_ID="<github_oauth_app_client_secret>"
export GRAFANA_OAUTH_CLIENT_SECRET="<github_oauth_app_client_secret>"
export GITHUB_ORG="<members_of_this_org_can_access_the_protected_resources>"
```
