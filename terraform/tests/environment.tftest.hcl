# Every run plans with a mock provider: no API access or infrastructure changes.
# Supply either committed example using terraform test -var-file=... .
mock_provider "proxmox" {}

variable "platform" {
  type = any
}

run "valid_example" {
  command = plan
}

run "valid_minimum_sizes_and_single_address_pool" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = { for name, node in var.platform.nodes : name => merge(node, {
        cpu = 2, memory_mib = node.role == "control-plane" ? 4096 : 2048, disk_gib = 10
      }) }
      metallb_pool = { start = var.platform.metallb_pool.start, end = var.platform.metallb_pool.start }
    })
  }
}

run "reject_empty_cluster" {
  command = plan
  variables {
    platform = merge(var.platform, {
      cluster_name = ""
    })
  }
  expect_failures = [var.platform]
}

run "reject_invalid_cluster_name" {
  command = plan
  variables {
    platform = merge(var.platform, {
      cluster_name = "Not a DNS name"
    })
  }
  expect_failures = [var.platform]
}

run "reject_http_endpoint" {
  command = plan
  variables {
    platform = merge(var.platform, {
      proxmox_endpoint = "http://pve.example.com:8006/"
    })
  }
  expect_failures = [var.platform]
}

run "reject_api_path_endpoint" {
  command = plan
  variables {
    platform = merge(var.platform, {
      proxmox_endpoint = "https://pve.example.com:8006/api2/json"
    })
  }
  expect_failures = [var.platform]
}

run "reject_endpoint_bad_port" {
  command = plan
  variables {
    platform = merge(var.platform, {
      proxmox_endpoint = "https://pve.example.com:65536/"
    })
  }
  expect_failures = [var.platform]
}

run "reject_endpoint_bad_host" {
  command = plan
  variables {
    platform = merge(var.platform, {
      proxmox_endpoint = "https://pve..example.com/"
    })
  }
  expect_failures = [var.platform]
}

run "reject_null_endpoint" {
  command = plan
  variables {
    platform = merge(var.platform, {
      proxmox_endpoint = null
    })
  }
  expect_failures = [var.platform]
}

run "reject_invalid_cidr" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { cidr = "bad-cidr" })
    })
  }
  expect_failures = [var.platform]
}

run "reject_noncanonical_cidr" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { cidr = "192.0.2.5/24" })
    })
  }
  expect_failures = [var.platform]
}

run "reject_ipv6_network" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { cidr = "2001:db8::/64" })
    })
  }
  expect_failures = [var.platform]
}

run "reject_outside_gateway" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { gateway = "203.0.113.1" })
    })
  }
  expect_failures = [var.platform]
}

run "reject_broadcast_gateway" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { gateway = cidrhost(var.platform.network.cidr, -1) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_null_network" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = null
    })
  }
  expect_failures = [var.platform]
}

run "reject_empty_dns" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { dns_servers = [] })
    })
  }
  expect_failures = [var.platform]
}

run "reject_invalid_dns" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { dns_servers = ["bad-address"] })
    })
  }
  expect_failures = [var.platform]
}

run "reject_duplicate_dns" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { dns_servers = [var.platform.network.dns_servers[0], var.platform.network.dns_servers[0]] })
    })
  }
  expect_failures = [var.platform]
}

run "reject_empty_domain" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { dns_domain = "" })
    })
  }
  expect_failures = [var.platform]
}

run "reject_invalid_domain" {
  command = plan
  variables {
    platform = merge(var.platform, {
      network = merge(var.platform.network, { dns_domain = "bad..example.com" })
    })
  }
  expect_failures = [var.platform]
}

run "reject_empty_nodes" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = {}
    })
  }
  expect_failures = [var.platform]
}

run "reject_null_nodes" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = null
    })
  }
  expect_failures = [var.platform]
}

run "reject_null_node" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = null })
    })
  }
  expect_failures = [var.platform]
}

run "reject_no_workers" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = { for name, node in var.platform.nodes : name => node if node.role == "control-plane" }
    })
  }
  expect_failures = [var.platform]
}

run "reject_two_control_planes" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge({ for name, node in var.platform.nodes : name => node if node.role == "worker" }, { cp01 = var.platform.nodes.cp01, cp02 = merge(var.platform.nodes.cp01, { address = cidrhost(var.platform.network.cidr, 12) }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_unknown_role" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { worker01 = merge(var.platform.nodes.worker01, { role = "unknown" }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_invalid_node_name" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { "Bad name" = merge(var.platform.nodes.worker01, { address = cidrhost(var.platform.network.cidr, 30) }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_reversed_pool" {
  command = plan
  variables {
    platform = merge(var.platform, {
      metallb_pool = { start = var.platform.metallb_pool.end, end = var.platform.metallb_pool.start }
    })
  }
  expect_failures = [var.platform]
}

run "reject_outside_pool" {
  command = plan
  variables {
    platform = merge(var.platform, {
      metallb_pool = { start = "203.0.113.200", end = "203.0.113.220" }
    })
  }
  expect_failures = [var.platform]
}

run "reject_pool_node_overlap" {
  command = plan
  variables {
    platform = merge(var.platform, {
      metallb_pool = { start = var.platform.nodes.cp01.address, end = var.platform.metallb_pool.end }
    })
  }
  expect_failures = [var.platform]
}

run "reject_pool_gateway_overlap" {
  command = plan
  variables {
    platform = merge(var.platform, {
      metallb_pool = { start = var.platform.network.gateway, end = var.platform.metallb_pool.end }
    })
  }
  expect_failures = [var.platform]
}

run "reject_pool_dns_overlap" {
  command = plan
  variables {
    platform = merge(var.platform, {
      metallb_pool = { start = var.platform.network.dns_servers[0], end = var.platform.metallb_pool.end }
    })
  }
  expect_failures = [var.platform]
}

run "reject_null_pool" {
  command = plan
  variables {
    platform = merge(var.platform, {
      metallb_pool = null
    })
  }
  expect_failures = [var.platform]
}

run "reject_empty_target" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { target_node = "" }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_empty_datastore" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { datastore = "" }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_empty_bridge" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { bridge = "" }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_invalid_vlan" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { vlan_id = 4095 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_fractional_vlan" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { vlan_id = 1.5 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_zero_vlan" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { vlan_id = 0 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_zero_cpu" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { cpu = 0 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_fractional_cpu" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { cpu = 2.5 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_excessive_cpu" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { cpu = 129 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_small_memory" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { memory_mib = 2048 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_fractional_memory" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { memory_mib = 4096.5 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_small_disk" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { disk_gib = 1 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_fractional_disk" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { disk_gib = 10.5 }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_null_size" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { cpu = null }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_malformed_address" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { address = "bad-address" }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_address_with_prefix" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { address = "192.0.2.11/24" }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_outside_node_address" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { address = "203.0.113.11" }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_network_node_address" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { address = cidrhost(var.platform.network.cidr, 0) }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_broadcast_node_address" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { address = cidrhost(var.platform.network.cidr, -1) }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_gateway_node_address" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { address = var.platform.network.gateway }) })
    })
  }
  expect_failures = [var.platform]
}

run "reject_duplicate_node_address" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(var.platform.nodes, { cp01 = merge(var.platform.nodes.cp01, { address = var.platform.nodes.worker01.address }) })
    })
  }
  expect_failures = [var.platform]
}

run "valid_five_control_planes_and_tagged_vlan" {
  command = plan
  variables {
    platform = merge(var.platform, {
      nodes = merge(
        { for name, node in var.platform.nodes : name => node if node.role == "worker" },
        { for index in range(1, 6) : "cp${index}" => merge(var.platform.nodes.cp01, {
          address = cidrhost(var.platform.network.cidr, 10 + index), vlan_id = 4094
        }) }
      )
    })
  }
}

run "valid_ipv4_endpoint_without_port" {
  command = plan
  variables {
    platform = merge(var.platform, { proxmox_endpoint = "https://203.0.113.10/" })
  }
}

run "reject_invalid_ipv4_endpoint" {
  command = plan
  variables {
    platform = merge(var.platform, { proxmox_endpoint = "https://999.999.999.999/" })
  }
  expect_failures = [var.platform]
}

run "reject_endpoint_userinfo" {
  command = plan
  variables {
    platform = merge(var.platform, { proxmox_endpoint = "https://user@pve.example.com/" })
  }
  expect_failures = [var.platform]
}
