provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "master" {
  name        = "control-plane"
  server_type = var.control_plane_server_type

}
