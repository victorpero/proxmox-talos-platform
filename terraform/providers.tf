# Credentials are read by the provider from PROXMOX_VE_API_TOKEN at runtime.
# This foundation declares no resources, data sources, or SSH configuration.
provider "proxmox" {
  endpoint = var.platform.proxmox_endpoint
  insecure = false
  min_tls  = "1.3"
}
