resource "hcloud_load_balancer" "load_balancer_worker" {
  name               = "lb-worker-0"
  location           = var.location
  load_balancer_type = var.load_balancer_type
  algorithm {
    type = "least_connections"
  }
  delete_protection = true
}

resource "hcloud_load_balancer_network" "lb_net" {
  load_balancer_id = hcloud_load_balancer.load_balancer_worker.id
  subnet_id        = hcloud_network_subnet.subnet.id
}
