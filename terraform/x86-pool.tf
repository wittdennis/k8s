resource "random_pet" "x86_node_name" {
  prefix = "worker"
  count  = var.x86_pool_count
}

resource "hcloud_server" "x86_pool" {
  name        = random_pet.x86_node_name.*.id[count.index]
  server_type = var.x86_pool_server_type
  count       = var.x86_pool_count
  location    = var.location
  image       = var.x86_pool_server_image
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
    hcloud_network_subnet.subnet,
    hcloud_firewall.firewall_worker
  ]
  user_data = file("./user-data/cloud-config.yaml")

  lifecycle {
    ignore_changes = [
      ssh_keys,
      user_data
    ]
  }
}

resource "hcloud_server_network" "x86_pool_network" {
  subnet_id = hcloud_network_subnet.subnet.id
  server_id = hcloud_server.x86_pool.*.id[count.index]
  count     = length(hcloud_server.x86_pool)
  depends_on = [
    hcloud_server.x86_pool
  ]
}

resource "hcloud_load_balancer_target" "lb_target_x86_pool" {
  type             = "server"
  load_balancer_id = hcloud_load_balancer.load_balancer_worker.id
  server_id        = hcloud_server.x86_pool.*.id[count.index]
  use_private_ip   = true
  count            = length(hcloud_server.x86_pool)
  depends_on = [
    hcloud_network_subnet.subnet,
    hcloud_server.x86_pool
  ]
}
