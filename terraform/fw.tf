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
    port        = "5473"
    description = "calico typha"
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
    port        = "5473"
    description = "calico typha"
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
