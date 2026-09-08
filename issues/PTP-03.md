## Objective

Build a reusable Terraform module that creates Talos-ready Proxmox virtual machines without hard-coding any environment topology.

## Scope

- Support declarative VM name, target node, CPU, memory, disk, datastore, network bridge, VLAN tag, address metadata, tags, and machine role.
- Support control-plane and worker VM creation from a Talos-compatible image or template strategy.
- Configure QEMU guest options and firmware settings only when required and documented.
- Make disks, NICs, boot order, and lifecycle behavior explicit.
- Produce stable outputs for VM identifiers, names, addresses, and role metadata needed by later Talos configuration.
- Add input validation and examples for single-node development and multi-node reference topologies.
- Keep the module independent of real Proxmox node names, bridges, and storage identifiers.

## Non-goals

- Bootstrapping Kubernetes.
- Managing workloads inside Talos.
- Embedding a specific private cluster size or storage layout.

## Acceptance criteria

- [ ] The module can declare both control-plane and worker VMs from input maps.
- [ ] CPU, memory, disk, target node, network, storage, and tags are configurable.
- [ ] Outputs expose only the information required by downstream configuration.
- [ ] No environment-specific Proxmox identifier is hard-coded in the module.
- [ ] Terraform plan is deterministic for unchanged inputs.
- [ ] Validation catches unsupported or incomplete VM definitions.
- [ ] Examples cover a minimal development topology and a multi-node reference topology.

## Dependencies

- PTP-02

## Suggested verification

- Run plans with at least two distinct fictional environment configurations.
- Change VM sizes and node counts and inspect the resulting plan.
- Confirm the module contains no copied private infrastructure identifiers.
- Exercise destroy/recreate behavior in an isolated Proxmox test environment when available.

## Affected areas

Terraform modules, Proxmox VM lifecycle, environment examples, outputs, and validation.
