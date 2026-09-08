## Objective

Create a versioned Talos image and machine-configuration workflow suitable for Proxmox while keeping generated secrets out of version control.

## Scope

- Pin the Talos version and document the upgrade policy.
- Define the Talos image or image-factory workflow required by the Proxmox VM module.
- Generate machine secrets outside committed source and propagate only required references through Terraform.
- Define control-plane and worker machine configuration patches.
- Configure cluster endpoint, machine networking, install disk selection, extensions where justified, and Kubernetes version compatibility.
- Mark sensitive Terraform outputs appropriately.
- Add validation for role-specific configuration and unsupported combinations.

## Non-goals

- Managing Talos through SSH.
- Committing machine secrets, talosconfig, kubeconfig, private keys, or generated credentials.
- Adding application workloads.

## Acceptance criteria

- [ ] Talos and Kubernetes versions are explicit and compatible.
- [ ] Control-plane and worker configurations are generated from reusable inputs.
- [ ] Generated secrets are never committed.
- [ ] Sensitive outputs are marked and excluded from normal documentation examples.
- [ ] Talos machines can boot from the documented Proxmox image path.
- [ ] Configuration patches are minimal, reviewable, and role-aware.
- [ ] Upgrade and regeneration behavior is documented.

## Dependencies

- PTP-03

## Suggested verification

- Generate configurations from a clean checkout with external secret material.
- Inspect generated files for expected role differences.
- Confirm repository scans contain no Talos secret material.
- Boot one isolated control-plane and worker VM using the documented image workflow.

## Affected areas

Talos image lifecycle, machine configuration, Terraform integration, secret handling, and version policy.
