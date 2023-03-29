terraform {
  required_version = ">= 1.4.2"

  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}
