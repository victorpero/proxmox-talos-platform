# Credentials are read by the provider from PROXMOX_VE_API_TOKEN at runtime.
# Guest creation uses the API only; ISO files are staged outside this module.
provider "proxmox" {
  endpoint = var.platform.proxmox_endpoint
  insecure = false
  min_tls  = "1.3"
}
