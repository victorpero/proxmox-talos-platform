# The map key is the VM name and stable Terraform identity; never use list indices.
resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes

  name        = each.key
  vm_id       = each.value.vm_id
  node_name   = each.value.target_node
  description = "Talos ${each.value.role} VM"
  tags        = sort(tolist(setunion(each.value.tags, toset(["talos", each.value.role]))))

  # UEFI with Secure Boot disabled supports the standard Talos amd64 ISO.
  bios          = "ovmf"
  machine       = "q35"
  scsi_hardware = "virtio-scsi-pci"
  boot_order    = ["scsi0", "ide2"]
  acpi          = true
  hotplug       = "0"

  started                              = each.value.started
  on_boot                              = each.value.on_boot
  reboot_after_update                  = true
  migrate                              = false
  stop_on_destroy                      = true
  purge_on_destroy                     = true
  delete_unreferenced_disks_on_destroy = false

  # The standard ISO has no QEMU guest agent. Never wait for guest-reported IPs.
  agent {
    enabled = false
  }

  cpu {
    cores   = each.value.cpu
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory_mib
    floating  = 0
  }

  disk {
    datastore_id = each.value.datastore
    interface    = "scsi0"
    file_format  = "raw"
    size         = each.value.disk_gib
    cache        = "none"
    discard      = "ignore"
    iothread     = false
    backup       = true
    replicate    = false
  }

  efi_disk {
    datastore_id      = each.value.datastore
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  cdrom {
    interface = "ide2"
    file_id   = each.value.iso_file_id
  }

  network_device {
    bridge       = each.value.bridge
    vlan_id      = each.value.vlan_id
    model        = "virtio"
    disconnected = false
    firewall     = false
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    create_before_destroy = false
  }
}
