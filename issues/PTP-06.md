## Objective

Use Ansible to provide a reproducible Proxmox-side baseline and preflight layer without overlapping Terraform or Talos ownership.

## Scope

- Create a Proxmox host inventory pattern with environment-specific values supplied externally.
- Add read-only preflight checks for Proxmox version, storage availability, bridges, time synchronization, virtualization support, and API reachability.
- Add narrowly scoped host-baseline roles for approved package, time, certificate, or operating-system settings where justified.
- Make every mutating role idempotent and independently selectable.
- Produce clear validation output that can be used before Terraform provisioning.
- Document where Ansible ownership ends and Terraform/Talos ownership begins.
- Keep real hostnames and management addresses out of the repository.

## Non-goals

- Configuring Talos over SSH.
- Reimplementing Proxmox VM lifecycle in Ansible.
- Managing every Proxmox host setting.

## Acceptance criteria

- [ ] Preflight checks run without mutating hosts by default.
- [ ] Mutating roles are explicit, idempotent, and limited to documented baseline settings.
- [ ] Inventory examples contain only fictional values.
- [ ] Ansible does not manage resources already owned by Terraform.
- [ ] Ansible does not attempt SSH configuration of Talos nodes.
- [ ] `ansible-lint` and YAML validation pass.
- [ ] Failure output identifies the specific missing prerequisite.

## Dependencies

- PTP-01

## Suggested verification

- Run preflight checks twice against an isolated Proxmox test host.
- Run any mutating baseline role twice and confirm the second run is unchanged.
- Review task ownership against Terraform and Talos responsibilities.
- Validate inventory files contain no private environment values.

## Affected areas

Ansible roles, inventories, Proxmox preflight checks, host baseline, and ownership documentation.
