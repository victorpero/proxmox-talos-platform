## Objective

Add dynamic Proxmox inventory and cross-tool validation so provisioned infrastructure can be inspected without maintaining duplicate static host lists.

## Scope

- Use the Proxmox dynamic inventory integration where appropriate.
- Group discovered guests by tags and role metadata created by Terraform.
- Add read-only playbooks that compare expected control-plane/worker counts with discovered Proxmox guests.
- Validate VM power state, configured resources, tags, and expected metadata.
- Produce concise human-readable and machine-readable validation output.
- Avoid assuming SSH access to Talos nodes; use Proxmox/Talos APIs for their respective validation paths.
- Document expected inventory behavior and tag conventions.

## Non-goals

- Using dynamic inventory as a second source of truth for infrastructure declarations.
- Configuring Talos through Ansible.
- Replacing Terraform plan/state or Talos health checks.

## Acceptance criteria

- [ ] Dynamic inventory discovers reference VMs without a static duplicate host list.
- [ ] Terraform-defined role tags map predictably into inventory groups.
- [ ] Validation detects missing, stopped, or incorrectly sized VMs.
- [ ] Validation remains read-only.
- [ ] Talos node validation uses Talos-native interfaces rather than SSH assumptions.
- [ ] Output is suitable for local use and CI artifacts.
- [ ] Inventory credentials are injected externally.

## Dependencies

- PTP-03
- PTP-06

## Suggested verification

- Compare dynamic inventory output against Terraform outputs.
- Stop or retag a test VM and confirm validation identifies the mismatch.
- Run inventory with no cached static host data.
- Confirm no access credential is written into generated artifacts.

## Affected areas

Ansible inventory, Proxmox API validation, Terraform tag conventions, operational checks, and CI evidence.
