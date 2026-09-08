variable "platform" {
  description = "Portable IPv4 environment definition. Contains no credentials; see README.md for field units, bounds, and state isolation."
  nullable    = false
  type = object({
    cluster_name     = string
    proxmox_endpoint = string
    network = object({
      cidr        = string
      gateway     = string
      dns_servers = list(string)
      dns_domain  = string
    })
    nodes = map(object({
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
    metallb_pool = object({
      start = string
      end   = string
    })
  })

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$|^[a-z]$", var.platform.cluster_name))
    error_message = "cluster_name must be a lowercase DNS label of 1-63 characters, starting with a letter."
  }

  validation {
    condition = try(
      can(regex("^https://[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?(:[0-9]{1,5})?/$", var.platform.proxmox_endpoint)) &&
      length(split(":", split("/", var.platform.proxmox_endpoint)[2])[0]) <= 253 &&
      (can(regex("^[0-9.]+$", split(":", split("/", var.platform.proxmox_endpoint)[2])[0])) ?
        can(cidrnetmask("${split(":", split("/", var.platform.proxmox_endpoint)[2])[0]}/32")) : true
      ) &&
      alltrue([for label in split(".", split(":", split("/", var.platform.proxmox_endpoint)[2])[0]) :
        can(regex("^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$", label))
      ]) &&
      (length(split(":", split("/", var.platform.proxmox_endpoint)[2])) == 1 ? true : (
        tonumber(split(":", split("/", var.platform.proxmox_endpoint)[2])[1]) >= 1 &&
        tonumber(split(":", split("/", var.platform.proxmox_endpoint)[2])[1]) <= 65535
      )), false
    )
    error_message = "proxmox_endpoint must be an HTTPS origin ending in /, with a valid host and optional port 1-65535; omit credentials, query strings, and /api2/json."
  }

  validation {
    condition = try(
      cidrnetmask(var.platform.network.cidr) != "" &&
      cidrhost(var.platform.network.cidr, 0) == split("/", var.platform.network.cidr)[0] &&
      tonumber(split("/", var.platform.network.cidr)[1]) >= 1 &&
      tonumber(split("/", var.platform.network.cidr)[1]) <= 30, false
    )
    error_message = "network.cidr must be a canonical IPv4 network with prefix length 1-30. IPv6 and dual-stack deployment are not supported yet."
  }

  validation {
    condition = try(
      cidrhost("${var.platform.network.gateway}/32", 0) == var.platform.network.gateway &&
      cidrhost("${var.platform.network.gateway}/${split("/", var.platform.network.cidr)[1]}", 0) == cidrhost(var.platform.network.cidr, 0) &&
      !contains([cidrhost(var.platform.network.cidr, 0), cidrhost(var.platform.network.cidr, -1)], var.platform.network.gateway), false
    )
    error_message = "network.gateway must be a usable IPv4 host in network.cidr, excluding network and broadcast addresses."
  }

  validation {
    condition = try(
      length(var.platform.network.dns_servers) >= 1 &&
      length(distinct(var.platform.network.dns_servers)) == length(var.platform.network.dns_servers) &&
      alltrue([for address in var.platform.network.dns_servers : cidrhost("${address}/32", 0) == address]) &&
      length(var.platform.network.dns_domain) <= 253 &&
      alltrue([for label in split(".", var.platform.network.dns_domain) :
        can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", label))
      ]), false
    )
    error_message = "DNS requires at least one distinct IPv4 server and a lowercase DNS domain with valid labels (no trailing dot)."
  }

  validation {
    condition = try(
      contains([1, 3, 5], length([for node in var.platform.nodes : node if node.role == "control-plane"])) &&
      alltrue([for name, node in var.platform.nodes :
        can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$|^[a-z]$", name)) &&
        contains(["control-plane", "worker"], node.role)
      ]), false
    )
    error_message = "nodes requires 1, 3, or 5 control-plane nodes; workers are optional; keys must be lowercase DNS labels starting with a letter and roles must be control-plane or worker."
  }

  validation {
    condition = try(alltrue([for node in var.platform.nodes :
      can(regex("^[A-Za-z][A-Za-z0-9-]{0,62}$", node.target_node)) &&
      can(regex("^[A-Za-z][A-Za-z0-9_.-]{0,63}$", node.datastore)) &&
      can(regex("^[A-Za-z][A-Za-z0-9_.-]{0,14}$", node.bridge)) &&
      (node.vlan_id == null ? true : (node.vlan_id >= 1 && node.vlan_id <= 4094 && floor(node.vlan_id) == node.vlan_id))
    ]), false)
    error_message = "Each node needs a valid target_node (1-63 characters), datastore (1-64), bridge (1-15), and either no VLAN or an integer VLAN ID 1-4094."
  }

  validation {
    condition = try(alltrue([for node in var.platform.nodes :
      node.cpu >= 2 && node.cpu <= 128 && floor(node.cpu) == node.cpu &&
      node.memory_mib >= (node.role == "control-plane" ? 4096 : 2048) &&
      node.memory_mib <= 1048576 && node.memory_mib % 1024 == 0 &&
      node.disk_gib >= 10 && node.disk_gib <= 65536 && floor(node.disk_gib) == node.disk_gib
    ]), false)
    error_message = "Node sizes require integer CPU cores 2-128, memory in 1024 MiB increments (control-plane 4096-1048576, worker 2048-1048576), and integer disk GiB 10-65536."
  }

  validation {
    condition = try(
      length(distinct([for node in var.platform.nodes : node.address])) == length(var.platform.nodes) &&
      alltrue([for node in var.platform.nodes :
        cidrhost("${node.address}/32", 0) == node.address &&
        cidrhost("${node.address}/${split("/", var.platform.network.cidr)[1]}", 0) == cidrhost(var.platform.network.cidr, 0) &&
        !contains([cidrhost(var.platform.network.cidr, 0), cidrhost(var.platform.network.cidr, -1), var.platform.network.gateway], node.address)
      ]), false
    )
    error_message = "Node addresses must be distinct usable IPv4 hosts in network.cidr and must not equal the gateway."
  }

  validation {
    condition = try(
      alltrue([for address in [var.platform.metallb_pool.start, var.platform.metallb_pool.end] :
        cidrhost("${address}/32", 0) == address &&
        cidrhost("${address}/${split("/", var.platform.network.cidr)[1]}", 0) == cidrhost(var.platform.network.cidr, 0) &&
        !contains([cidrhost(var.platform.network.cidr, 0), cidrhost(var.platform.network.cidr, -1)], address)
      ]) &&
      sum([for i, octet in split(".", var.platform.metallb_pool.start) : tonumber(octet) * pow(256, 3 - i)]) <=
      sum([for i, octet in split(".", var.platform.metallb_pool.end) : tonumber(octet) * pow(256, 3 - i)]) &&
      alltrue([for address in concat([var.platform.network.gateway], var.platform.network.dns_servers, [for node in var.platform.nodes : node.address]) :
        sum([for i, octet in split(".", address) : tonumber(octet) * pow(256, 3 - i)]) <
        sum([for i, octet in split(".", var.platform.metallb_pool.start) : tonumber(octet) * pow(256, 3 - i)]) ||
        sum([for i, octet in split(".", address) : tonumber(octet) * pow(256, 3 - i)]) >
        sum([for i, octet in split(".", var.platform.metallb_pool.end) : tonumber(octet) * pow(256, 3 - i)])
      ]), false
    )
    error_message = "metallb_pool must be an ordered, inclusive IPv4 range of usable hosts in network.cidr, excluding the gateway, DNS servers, and node addresses."
  }
}
