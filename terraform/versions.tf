terraform {
  required_version = ">= 1.13.3, < 1.14.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "= 0.112.0"
    }
  }

  # Override the backend type locally when a remote state store is available.
  backend "local" {}
}
