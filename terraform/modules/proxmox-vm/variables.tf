variable "nodes" {
  description = "VMs keyed by DNS name. Addresses are downstream metadata only. ISO files must already exist on each target node."
  nullable    = false
  type = map(object({
    vm_id       = number
    iso_file_id = string
    tags        = optional(set(string), [])
    started     = optional(bool, true)
    on_boot     = optional(bool, true)
    role        = string
    target_node = string
    datastore   = string
    bridge      = string
    vlan_id     = optional(number)
    address     = string
    cpu         = number
    memory_mib  = number
    disk_gib    = number
  }))

  validation {
    condition = try(alltrue([for name, node in var.nodes :
      can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$|^[a-z]$", name)) &&
      contains(["control-plane", "worker"], node.role)
    ]), false)
    error_message = "VM map keys must be lowercase DNS labels starting with a letter; roles must be control-plane or worker."
  }

  validation {
    condition = try(
      length(distinct([for node in var.nodes : node.vm_id])) == length(var.nodes) &&
      alltrue([for node in var.nodes : node.vm_id >= 100 && node.vm_id <= 999999999 && floor(node.vm_id) == node.vm_id]), false
    )
    error_message = "VM IDs must be distinct integers between 100 and 999999999, reserved cluster-wide by the operator."
  }

  validation {
    condition = try(alltrue([for node in var.nodes :
      can(regex("^[A-Za-z][A-Za-z0-9_.-]{0,63}:iso/[A-Za-z0-9][A-Za-z0-9_.-]*\\.iso$", node.iso_file_id))
    ]), false)
    error_message = "iso_file_id must identify an existing Talos amd64 ISO as datastore:iso/filename.iso; paths, URLs, templates, and disk images are unsupported."
  }

  validation {
    condition = try(alltrue([for node in var.nodes : alltrue([for tag in node.tags :
      can(regex("^[a-z0-9_][a-z0-9_.-]*$", tag))
    ])]), false)
    error_message = "Tags must be nonempty lowercase Proxmox tags using letters, digits, underscore, dot, or hyphen, starting with a letter, digit, or underscore."
  }

  validation {
    condition = try(
      length(distinct([for node in var.nodes : node.address])) == length(var.nodes) &&
      alltrue([for node in var.nodes : cidrhost("${node.address}/32", 0) == node.address]), false
    )
    error_message = "Address metadata must contain distinct IPv4 addresses without CIDR prefixes."
  }

  validation {
    condition = try(alltrue([for node in var.nodes :
      can(regex("^[A-Za-z][A-Za-z0-9-]{0,62}$", node.target_node)) &&
      can(regex("^[A-Za-z][A-Za-z0-9_.-]{0,63}$", node.datastore)) &&
      can(regex("^[A-Za-z][A-Za-z0-9_.-]{0,14}$", node.bridge)) &&
      (node.vlan_id == null ? true : (node.vlan_id >= 1 && node.vlan_id <= 4094 && floor(node.vlan_id) == node.vlan_id))
    ]), false)
    error_message = "Each node needs a valid target_node (1-63 characters), datastore (1-64), bridge (1-15), and either no VLAN or an integer VLAN ID 1-4094."
  }

  validation {
    condition = try(alltrue([for node in var.nodes :
      node.cpu >= 2 && node.cpu <= 128 && floor(node.cpu) == node.cpu &&
      node.memory_mib >= (node.role == "control-plane" ? 4096 : 2048) &&
      node.memory_mib <= 1048576 && node.memory_mib % 1024 == 0 &&
      node.disk_gib >= 10 && node.disk_gib <= 65536 && floor(node.disk_gib) == node.disk_gib
    ]), false)
    error_message = "Node sizes require integer CPU cores 2-128, memory in 1024 MiB increments (control-plane 4096-1048576, worker 2048-1048576), and integer disk GiB 10-65536."
  }
}
