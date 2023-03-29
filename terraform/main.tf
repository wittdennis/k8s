provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "default" {
  name     = "kubenet"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.default.id
  type         = "server"
  network_zone = "eu-central"
  ip_range     = "10.96.0.0/16"
  depends_on = [
    hcloud_network.default
  ]
}

resource "hcloud_server" "master" {
  name        = "control-plane-${count.index}"
  server_type = var.control_plane_server_type
  count       = 1
  location    = var.location
  image       = var.control_plane_server_image
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
  firewall_ids = [hcloud_firewall.firewall_master.id]
  labels = {
    "role" : "k8s-control"
  }
  depends_on = [
    hcloud_network_subnet.subnet
  ]
}

resource "hcloud_server_network" "master_network" {
  subnet_id = hcloud_network_subnet.subnet.id
  server_id = hcloud_server.master.*.id[count.index]
  count     = length(hcloud_server.master)
}

resource "hcloud_server" "worker" {
  name        = "worker-${count.index}"
  server_type = var.worker_server_type
  count       = var.worker_count
  location    = var.location
  image       = var.worker_server_image
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
  firewall_ids = [hcloud_firewall.firewall_worker.id]
  labels = {
    "role" : "k8s-worker"
  }
  depends_on = [
    hcloud_network_subnet.subnet
  ]
}

resource "hcloud_server_network" "worker_network" {
  subnet_id = hcloud_network_subnet.subnet.id
  server_id = hcloud_server.worker.*.id[count.index]
  count     = length(hcloud_server.worker)
}

resource "hcloud_load_balancer" "load_balancer" {
  name               = "lb-0"
  location           = var.location
  load_balancer_type = var.load_balancer_type
  algorithm {
    type = "least_connections"
  }
}

resource "hcloud_load_balancer_target" "lb_target" {
  type             = "server"
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  server_id        = hcloud_server.worker.*.id[count.index]
  use_private_ip   = true
  count            = length(hcloud_server.worker)
}

resource "hcloud_load_balancer_network" "lb_net" {
  load_balancer_id = hcloud_load_balancer.load_balancer.id
  subnet_id        = hcloud_network_subnet.subnet.id
}

resource "hcloud_firewall" "firewall_worker" {
  name = "fw-worker-0"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall" "firewall_master" {
  name = "fw-master-0"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}
