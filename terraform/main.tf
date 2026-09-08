module "vms" {
  source = "./modules/proxmox-vm"
  nodes  = var.platform.nodes
}
