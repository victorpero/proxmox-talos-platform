# Security model

## Public-repository boundary

This repository is designed to be safe to publish. It must not contain values copied from a private infrastructure environment.

Use documentation-only values in committed examples:

- `pve.example.com`
- `cluster.example.com`
- `192.0.2.0/24`
- `198.51.100.0/24`
- `203.0.113.0/24`

## Secrets

Credentials are injected at runtime through environment variables, secret stores, or encrypted configuration. Sensitive generated files remain ignored.

At minimum, keep the following outside version control:

- Proxmox API credentials
- Terraform state containing sensitive outputs
- Talos machine secrets
- kubeconfig and talosconfig
- private encryption keys
- real DNS provider credentials

## Least privilege

The Proxmox automation identity should receive only the privileges required to manage the resources covered by this reference platform. Kubernetes service accounts and GitHub Actions permissions should also be scoped to the minimum required operations.

## Supply chain

CI should validate pinned provider/module versions, scan infrastructure definitions, detect committed secrets, and avoid unpinned third-party workflow actions.
