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
