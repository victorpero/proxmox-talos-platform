output "nodes" {
  description = "Stable name-keyed VM identity and declared address/role metadata for downstream Talos configuration; addresses are not observed or configured."
  value = { for name, vm in proxmox_virtual_environment_vm.this : name => {
    vm_id       = vm.vm_id
    name        = vm.name
    target_node = vm.node_name
    address     = var.nodes[name].address
    role        = var.nodes[name].role
  } }
}
