# Plan-only tests use the real provider schema with all API operations mocked.
mock_provider "proxmox" {}

variable "platform" {
  type = any
}

run "root_wires_all_nodes" {
  command = plan
  assert {
    condition = output.nodes == { for name, node in var.platform.nodes : name => {
      vm_id   = node.vm_id, name = name, target_node = node.target_node,
      address = node.address, role = node.role
    } }
    error_message = "Root outputs must expose exactly the downstream VM metadata for every input name."
  }
}

run "module_vm_contract" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = var.platform.nodes }

  assert {
    condition = length(proxmox_virtual_environment_vm.this) == length(var.nodes) && alltrue([
      for name, vm in proxmox_virtual_environment_vm.this :
      vm.vm_id == var.nodes[name].vm_id && vm.name == name &&
      vm.node_name == var.nodes[name].target_node &&
      vm.cpu[0].cores == var.nodes[name].cpu &&
      vm.memory[0].dedicated == var.nodes[name].memory_mib &&
      vm.disk[0].size == var.nodes[name].disk_gib &&
      vm.disk[0].datastore_id == var.nodes[name].datastore &&
      vm.efi_disk[0].datastore_id == var.nodes[name].datastore &&
      vm.network_device[0].bridge == var.nodes[name].bridge &&
      vm.network_device[0].vlan_id == var.nodes[name].vlan_id &&
      vm.cdrom[0].file_id == var.nodes[name].iso_file_id &&
      toset(vm.tags) == setunion(var.nodes[name].tags, toset(["talos", var.nodes[name].role]))
    ])
    error_message = "Each VM must preserve its input identity, placement, compute, disks, NIC, ISO, and tags."
  }

  assert {
    condition = alltrue([for vm in proxmox_virtual_environment_vm.this :
      vm.bios == "ovmf" && vm.machine == "q35" &&
      vm.efi_disk[0].type == "4m" && !vm.efi_disk[0].pre_enrolled_keys &&
      vm.scsi_hardware == "virtio-scsi-pci" && vm.disk[0].interface == "scsi0" &&
      vm.disk[0].file_format == "raw" && vm.disk[0].cache == "none" &&
      !vm.disk[0].iothread && vm.cdrom[0].interface == "ide2" &&
      vm.boot_order == tolist(["scsi0", "ide2"]) && vm.network_device[0].model == "virtio" &&
      vm.cpu[0].type == "x86-64-v2-AES" && vm.cpu[0].sockets == 1 &&
      vm.memory[0].floating == 0 && vm.hotplug == "0" && !vm.agent[0].enabled &&
      length(vm.initialization) == 0 && length(vm.clone) == 0 &&
      vm.started && vm.on_boot && vm.reboot_after_update && !vm.migrate &&
      vm.stop_on_destroy && vm.purge_on_destroy && !vm.delete_unreferenced_disks_on_destroy
    ])
    error_message = "Talos boot, firmware, memory, guest-agent, and lifecycle settings must remain explicit."
  }
}

run "unchanged_inputs_preserve_metadata" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = var.platform.nodes }
  assert {
    condition     = output.nodes == run.module_vm_contract.nodes
    error_message = "Repeated plans must produce identical declared output metadata."
  }
}

run "single_control_plane_vm" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = var.platform.nodes.cp01 } }
  assert {
    condition     = length(proxmox_virtual_environment_vm.this) == 1 && output.nodes.cp01.role == "control-plane"
    error_message = "The reusable module must support a single control-plane VM without workers."
  }
}

run "workers_only_and_resized" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables {
    nodes = { worker01 = merge(var.platform.nodes.cp01, {
      role    = "worker", cpu = 8, memory_mib = 16384, disk_gib = 64,
      started = false, on_boot = false, tags = ["z-example", "a-example", "z-example"]
    }) }
  }
  assert {
    condition = (length(proxmox_virtual_environment_vm.this) == 1 &&
      output.nodes.worker01.role == "worker" &&
      proxmox_virtual_environment_vm.this["worker01"].cpu[0].cores == 8 &&
      proxmox_virtual_environment_vm.this["worker01"].memory[0].dedicated == 16384 &&
      proxmox_virtual_environment_vm.this["worker01"].disk[0].size == 64 &&
      !proxmox_virtual_environment_vm.this["worker01"].started &&
      !proxmox_virtual_environment_vm.this["worker01"].on_boot &&
    proxmox_virtual_environment_vm.this["worker01"].tags == tolist(["a-example", "talos", "worker", "z-example"]))
    error_message = "Standalone workers, resizing, stopped VMs, and canonical tag ordering must be supported."
  }
}

run "added_node_preserves_existing_identity" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables {
    nodes = merge(var.platform.nodes, {
      extra = merge(var.platform.nodes.cp01, { vm_id = 9001, address = cidrhost(var.platform.network.cidr, 40), role = "worker" })
    })
  }
  assert {
    condition = (length(proxmox_virtual_environment_vm.this) == length(var.platform.nodes) + 1 &&
    alltrue([for name, node in var.platform.nodes : output.nodes[name] == run.module_vm_contract.nodes[name]]))
    error_message = "Adding a map entry must not renumber or rename existing VMs."
  }
}

run "empty_module_map" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = {} }
  assert {
    condition     = length(proxmox_virtual_environment_vm.this) == 0
    error_message = "An empty module map must declare no VMs."
  }
}

run "reject_low_vm_id" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { vm_id = 99 }) } }
  expect_failures = [var.nodes]
}

run "reject_high_vm_id" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { vm_id = 1000000000 }) } }
  expect_failures = [var.nodes]
}

run "reject_fractional_vm_id" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { vm_id = 100.5 }) } }
  expect_failures = [var.nodes]
}

run "reject_null_vm_id" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { vm_id = null }) } }
  expect_failures = [var.nodes]
}

run "reject_empty_iso" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { iso_file_id = "" }) } }
  expect_failures = [var.nodes]
}

run "reject_url_iso" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { iso_file_id = "https://example.com/talos.iso" }) } }
  expect_failures = [var.nodes]
}

run "reject_wrong_image_format" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { iso_file_id = "example-storage:iso/talos.raw" }) } }
  expect_failures = [var.nodes]
}

run "reject_iso_path_traversal" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { iso_file_id = "example-storage:iso/../talos.iso" }) } }
  expect_failures = [var.nodes]
}

run "reject_null_iso" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { iso_file_id = null }) } }
  expect_failures = [var.nodes]
}

run "reject_uppercase_tag" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { tags = ["BadTag"] }) } }
  expect_failures = [var.nodes]
}

run "reject_tag_separator" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { tags = ["one;two"] }) } }
  expect_failures = [var.nodes]
}

run "reject_empty_tag" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { tags = [""] }) } }
  expect_failures = [var.nodes]
}

run "reject_null_tag" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { tags = [null] }) } }
  expect_failures = [var.nodes]
}

run "reject_unknown_role" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { role = "unknown" }) } }
  expect_failures = [var.nodes]
}

run "reject_empty_target" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { target_node = "" }) } }
  expect_failures = [var.nodes]
}

run "reject_empty_storage" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { datastore = "" }) } }
  expect_failures = [var.nodes]
}

run "reject_empty_bridge" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { bridge = "" }) } }
  expect_failures = [var.nodes]
}

run "reject_invalid_vlan" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { vlan_id = 4095 }) } }
  expect_failures = [var.nodes]
}

run "reject_zero_vlan" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { vlan_id = 0 }) } }
  expect_failures = [var.nodes]
}

run "reject_fractional_vlan" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { vlan_id = 1.5 }) } }
  expect_failures = [var.nodes]
}

run "reject_small_cpu" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { cpu = 1 }) } }
  expect_failures = [var.nodes]
}

run "reject_fractional_cpu" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { cpu = 2.5 }) } }
  expect_failures = [var.nodes]
}

run "reject_small_memory" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { memory_mib = 2048 }) } }
  expect_failures = [var.nodes]
}

run "reject_fractional_memory" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { memory_mib = 4096.5 }) } }
  expect_failures = [var.nodes]
}

run "reject_small_disk" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { disk_gib = 9 }) } }
  expect_failures = [var.nodes]
}

run "reject_fractional_disk" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { disk_gib = 10.5 }) } }
  expect_failures = [var.nodes]
}

run "reject_invalid_address" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { address = "bad-address" }) } }
  expect_failures = [var.nodes]
}

run "reject_cidr_address" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { address = "192.0.2.11/24" }) } }
  expect_failures = [var.nodes]
}

run "reject_null_address" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = merge(var.platform.nodes.cp01, { address = null }) } }
  expect_failures = [var.nodes]
}

run "reject_invalid_name" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { "Bad name" = var.platform.nodes.cp01 } }
  expect_failures = [var.nodes]
}

run "reject_duplicate_ids" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = var.platform.nodes.cp01, cp02 = merge(var.platform.nodes.cp01, { address = cidrhost(var.platform.network.cidr, 40) }) } }
  expect_failures = [var.nodes]
}

run "reject_duplicate_addresses" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = var.platform.nodes.cp01, cp02 = merge(var.platform.nodes.cp01, { vm_id = 9001 }) } }
  expect_failures = [var.nodes]
}

run "reject_null_node" {
  command = plan
  module { source = "./modules/proxmox-vm" }
  variables { nodes = { cp01 = null } }
  expect_failures = [var.nodes]
}
