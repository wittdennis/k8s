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

resource "hcloud_server" "worker" {
  name        = "worker-${count.index}"
  server_type = var.worker_server_type
  count       = var.worker_count
  location    = var.location
  image       = var.worker_server_image
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  firewall_ids = [hcloud_firewall.firewall_worker.id]
  ssh_keys     = [hcloud_ssh_key.default.id]
  labels = {
    "role" : "k8s-worker"
  }
  depends_on = [
    hcloud_network_subnet.subnet
  ]
  user_data = file("./user-data/cloud-config.yaml")
}

resource "hcloud_server_network" "worker_network" {
  subnet_id = hcloud_network_subnet.subnet.id
  server_id = hcloud_server.worker.*.id[count.index]
  count     = length(hcloud_server.worker)
}

resource "hcloud_load_balancer" "load_balancer_worker" {
  name               = "lb-worker-0"
  location           = var.location
  load_balancer_type = var.load_balancer_type
  algorithm {
    type = "least_connections"
  }
  depends_on = [
    hcloud_server.worker
  ]
  delete_protection = true
}

resource "hcloud_load_balancer_target" "lb_target" {
  type             = "server"
  load_balancer_id = hcloud_load_balancer.load_balancer_worker.id
  server_id        = hcloud_server.worker.*.id[count.index]
  use_private_ip   = true
  count            = length(hcloud_server.worker)
  depends_on = [
    hcloud_network_subnet.subnet
  ]
}

resource "hcloud_load_balancer_network" "lb_net" {
  load_balancer_id = hcloud_load_balancer.load_balancer_worker.id
  subnet_id        = hcloud_network_subnet.subnet.id
}

resource "hcloud_firewall" "firewall_worker" {
  name = "fw-worker-0"

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    description = "ssh"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "any"
    description = "private net open"
    source_ips = [
      hcloud_network_subnet.subnet.ip_range
    ]
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "any"
    description = "private net open"
    source_ips = [
      hcloud_network_subnet.subnet.ip_range
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10250"
    description = "kubelet-api"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10260"
    description = "cert-manager-webhook"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9100"
    description = "node-exporter"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "30000-32767"
    description = "nodeport"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "30000-32767"
    description = "nodeport"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall" "firewall_master" {
  name = "fw-master-0"
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    description = "ssh"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10257"
    description = "kube-controller-manager"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10259"
    description = "kube-scheduler"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    description = "kube-apiserver"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10250"
    description = "kubelet-api"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "any"
    description = "private net open"
    source_ips = [
      hcloud_network_subnet.subnet.ip_range
    ]
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "any"
    description = "private net open"
    source_ips = [
      hcloud_network_subnet.subnet.ip_range
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10260"
    description = "cert-manager-webhook"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9100"
    description = "node-exporter"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "30000-32767"
    description = "nodeport"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "30000-32767"
    description = "nodeport"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}
