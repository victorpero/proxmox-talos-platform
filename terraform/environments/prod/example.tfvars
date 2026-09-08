# Documentation-only values. These do not represent a real environment.
proxmox_api_url = "https://pve.example.com:8006/api2/json"
cluster_name    = "talos-prod"
network_cidr    = "198.51.100.0/24"
gateway         = "198.51.100.1"

control_plane_nodes = {
  cp01 = { address = "198.51.100.11", cpu = 4, memory = 8192 }
  cp02 = { address = "198.51.100.12", cpu = 4, memory = 8192 }
  cp03 = { address = "198.51.100.13", cpu = 4, memory = 8192 }
}

worker_nodes = {
  worker01 = { address = "198.51.100.21", cpu = 8, memory = 16384 }
  worker02 = { address = "198.51.100.22", cpu = 8, memory = 16384 }
}

metallb_pool = {
  start = "198.51.100.200"
  end   = "198.51.100.220"
}
