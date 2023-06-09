provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "default" {
  name       = "ssh key"
  public_key = file(var.ssh_key_file)
}

resource "hcloud_server" "master" {
  name        = "control-plane-${count.index}"
  server_type = var.control_plane_server_type
  count       = 1
  location    = var.location
  image       = var.control_plane_server_image
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  firewall_ids = [hcloud_firewall.firewall_master.id]
  ssh_keys     = [hcloud_ssh_key.default.id]
  labels = {
    "role" : "k8s-control"
  }
  depends_on = [
    hcloud_network_subnet.subnet
  ]
  user_data = file("./user-data/cloud-config.yaml")
}

resource "hcloud_server_network" "master_network" {
  subnet_id = hcloud_network_subnet.subnet.id
  server_id = hcloud_server.master.*.id[count.index]
  count     = length(hcloud_server.master)
}
