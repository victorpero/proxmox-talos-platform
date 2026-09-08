output "nodes" {
  description = "VM identity and declared address/role metadata for downstream Talos configuration."
  value       = module.vms.nodes
}
