# Fictional documentation values; never use these to target a real environment.
platform = {
  cluster_name     = "talos-prod"
  proxmox_endpoint = "https://pve.example.com:8006/"
  network = {
    cidr        = "198.51.100.0/24"
    gateway     = "198.51.100.1"
    dns_servers = ["198.51.100.53"]
    dns_domain  = "prod.example.com"
  }
  nodes = {
    cp01 = {
      role        = "control-plane"
      target_node = "pve-example-1"
      datastore   = "example-vm-storage"
      bridge      = "vmbr-example"
      vlan_id     = 120
      address     = "198.51.100.11"
      cpu         = 4
      memory_mib  = 8192
      disk_gib    = 32
    }
    cp02 = {
      role        = "control-plane"
      target_node = "pve-example-2"
      datastore   = "example-vm-storage"
      bridge      = "vmbr-example"
      vlan_id     = 120
      address     = "198.51.100.12"
      cpu         = 4
      memory_mib  = 8192
      disk_gib    = 32
    }
    cp03 = {
      role        = "control-plane"
      target_node = "pve-example-3"
      datastore   = "example-vm-storage"
      bridge      = "vmbr-example"
      vlan_id     = 120
      address     = "198.51.100.13"
      cpu         = 4
      memory_mib  = 8192
      disk_gib    = 32
    }
    worker01 = {
      role        = "worker"
      target_node = "pve-example-1"
      datastore   = "example-vm-storage"
      bridge      = "vmbr-example"
      vlan_id     = 120
      address     = "198.51.100.21"
      cpu         = 8
      memory_mib  = 16384
      disk_gib    = 32
    }
    worker02 = {
      role        = "worker"
      target_node = "pve-example-2"
      datastore   = "example-vm-storage"
      bridge      = "vmbr-example"
      vlan_id     = 120
      address     = "198.51.100.22"
      cpu         = 8
      memory_mib  = 16384
      disk_gib    = 32
    }
  }
  metallb_pool = {
    start = "198.51.100.200"
    end   = "198.51.100.220"
  }
}
