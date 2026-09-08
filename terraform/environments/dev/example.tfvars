# Documentation-only values. These do not represent a real environment.
proxmox_api_url = "https://pve.example.com:8006/api2/json"
cluster_name    = "talos-dev"
network_cidr    = "192.0.2.0/24"
gateway         = "192.0.2.1"

control_plane_nodes = {
  cp01 = {
    address = "192.0.2.11"
    cpu     = 4
    memory  = 8192
  }
}

worker_nodes = {
  worker01 = {
    address = "192.0.2.21"
    cpu     = 4
    memory  = 8192
  }
}

metallb_pool = {
  start = "192.0.2.200"
  end   = "192.0.2.220"
}
