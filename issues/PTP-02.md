## Objective

Establish a reproducible Terraform foundation for Proxmox with pinned providers, portable environment configuration, and safe credential handling.

## Scope

- Configure Terraform with the selected Proxmox provider and explicit version constraints.
- Define provider configuration without embedding credentials in HCL or committed variable files.
- Create reusable environment inputs for cluster name, Proxmox endpoint, target node selection, storage, bridges, VLANs, DNS, and address plans.
- Keep `dev` and `prod` examples structurally identical while using documentation-only values.
- Define provider aliases or module boundaries only where they improve clarity.
- Document local state for development and a pluggable remote-state strategy without requiring a specific backend.
- Add variable validation for malformed addresses, unsupported node counts, invalid resource sizes, and unsafe empty values.

## Non-goals

- Creating Talos VMs.
- Managing Proxmox itself as a complete configuration-management target.
- Committing a real Terraform state file or backend credentials.

## Acceptance criteria

- [ ] `terraform init` succeeds from a clean checkout.
- [ ] Provider and Terraform version constraints are explicit.
- [ ] `terraform fmt -check` and `terraform validate` pass.
- [ ] Credentials are supplied externally and are absent from committed files.
- [ ] Environment examples use only fictional, documentation-safe infrastructure values.
- [ ] Variables are documented and reject clearly invalid input.
- [ ] Backend choices are documented without coupling the project to a private environment.

## Dependencies

- PTP-01

## Suggested verification

- Initialize each example environment.
- Run formatting and validation checks.
- Inspect provider configuration and example variables for secrets or private infrastructure values.
- Exercise invalid variable inputs and confirm useful failures.

## Affected areas

Terraform root configuration, providers, variables, example environments, state strategy, and documentation.
