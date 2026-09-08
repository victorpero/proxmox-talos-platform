# Fictional documentation values; never use these to target a real environment.
platform = {
  cluster_name     = "talos-dev"
  proxmox_endpoint = "https://pve.example.com:8006/"
  network = {
    cidr        = "192.0.2.0/24"
    gateway     = "192.0.2.1"
    dns_servers = ["192.0.2.53"]
    dns_domain  = "dev.example.com"
  }
  nodes = {
    cp01 = {
      role        = "control-plane"
      target_node = "pve-example-1"
      datastore   = "example-vm-storage"
      bridge      = "vmbr-example"
      vlan_id     = null
      address     = "192.0.2.11"
      cpu         = 4
      memory_mib  = 8192
      disk_gib    = 32
    }
    worker01 = {
      role        = "worker"
      target_node = "pve-example-1"
      datastore   = "example-vm-storage"
      bridge      = "vmbr-example"
      vlan_id     = null
      address     = "192.0.2.21"
      cpu         = 4
      memory_mib  = 8192
      disk_gib    = 32
    }
  }
  metallb_pool = {
    start = "192.0.2.200"
    end   = "192.0.2.220"
  }
}
