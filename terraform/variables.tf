# Set value in *.tfvars file
variable "hcloud_token" {
  default     = ""
  description = "Hetzner API token"
}

variable "location" {
  default     = "fsn1"
  description = "The datacenter all resources should be created in"
}

variable "control_plane_server_type" {
  default     = "cx21"
  description = "Type of vServer to use for the k8s control plane"
}

variable "control_plane_server_image" {
  default     = "fedora-37"
  description = "OS image of the control nodes"
}

variable "worker_server_type" {
  default     = "cpx31"
  description = "Type of vServer to use for the k8s worker nodes"
}

variable "worker_server_image" {
  default     = "fedora-37"
  description = "OS image of the worker nodes"
}

variable "worker_count" {
  default     = 1
  description = "Number of worker nodes to create"
}

variable "load_balancer_type" {
  default     = "lb11"
  description = "Type of the load balancer to create"
}

variable "ssh_key_file" {
  default     = "~/.ssh/id_ed25519.pub"
  description = "SSH key to add to all nodes to connect to server"
}
