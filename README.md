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
```
