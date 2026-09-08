# Proxmox Talos Platform

A public reference implementation for provisioning and operating a Talos Linux Kubernetes platform on Proxmox using Terraform, Ansible, Flux, Traefik, MetalLB, and observability tooling.

This repository is intentionally designed as a portable infrastructure engineering showcase. It does **not** mirror any private homelab environment. Hostnames, domains, addresses, identifiers, storage names, and topology examples are documentation-only values.

## Architecture

```text
Proxmox
   │
Terraform
   │
   ├── Talos control-plane VMs
   └── Talos worker VMs
          │
          ▼
       Talos Linux
          │
          ▼
      Kubernetes
          │
    ┌─────┼───────────┐
    │     │           │
  Flux  Traefik    MetalLB
    │
Applications
    │
Monitoring
```

Ansible is used for Proxmox-side baseline configuration, preflight checks, inventory, and operational validation. Talos nodes remain API-managed and immutable rather than being configured over SSH.

## Repository layout

```text
terraform/
  modules/proxmox-vm/
  environments/dev/
  environments/prod/
ansible/
  roles/proxmox/
  playbooks/
kubernetes/
  flux/
  traefik/
  metallb/
  monitoring/
  applications/
docs/
  architecture.md
  security.md
  disaster-recovery.md
issues/
scripts/
```

## Addressing policy

All committed network examples use documentation ranges defined for examples, such as `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`. No committed value should be assumed to represent a real environment.

Example values belong in `*.example.tfvars`, example inventory files, or documentation. Real credentials, IP addresses, DNS names, storage identifiers, MAC addresses, and environment-specific state must remain outside the repository.

## Intended workflow

```text
feature/* → dev → main
```

- `main` represents the reviewed public reference release.
- `dev` is the integration branch.
- feature work is tracked by `PTP-XX` issues.
- infrastructure changes are validated before merge.

## Roadmap

The initial roadmap is tracked as `PTP-01` onward and covers:

- repository and provider bootstrap
- reusable Proxmox VM provisioning
- Talos image and machine configuration
- Kubernetes cluster bootstrap
- Ansible Proxmox baseline and validation
- networking with MetalLB and Traefik
- Flux GitOps
- secrets and security hardening
- observability
- CI and security validation
- disaster recovery and rebuild testing
- final documentation and portfolio acceptance

## Security

Never commit:

- Proxmox API tokens
- private keys
- Talos machine secrets
- kubeconfig or talosconfig files
- Terraform state containing sensitive values
- real infrastructure addresses or identifiers

See [`docs/security.md`](docs/security.md).

## Status

Initial project planning and repository bootstrap.
