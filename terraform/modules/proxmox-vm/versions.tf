terraform {
  required_version = ">= 1.13.3, < 1.14.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.112.0"
    }
  }
}
