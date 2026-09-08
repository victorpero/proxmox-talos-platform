# Architecture

## Goals

The platform demonstrates a repeatable infrastructure lifecycle for a Kubernetes cluster running Talos Linux on Proxmox.

The design separates responsibilities deliberately:

- **Terraform** owns Proxmox VM lifecycle and infrastructure declarations.
- **Talos tooling/provider integration** owns Talos machine configuration and Kubernetes bootstrap.
- **Ansible** owns Proxmox-side baseline configuration, preflight checks, inventory, and operational validation.
- **Flux** owns continuous reconciliation of Kubernetes workloads and platform add-ons.
- **Traefik** provides ingress.
- **MetalLB** provides load-balancer addresses in bare-metal or virtualized environments.
- **Monitoring tooling** provides cluster and platform visibility.

## Reference topology

```text
                 Proxmox cluster
                       │
                Terraform API
                       │
          ┌────────────┴────────────┐
          │                         │
   Control-plane VMs           Worker VMs
          │                         │
          └────────────┬────────────┘
                       │
                  Talos Linux
                       │
                  Kubernetes
                       │
      ┌────────────────┼────────────────┐
      │                │                │
     Flux           Traefik          MetalLB
      │
 applications + monitoring
```

## Portability

The reference implementation must not assume a specific Proxmox node name, bridge, VLAN, datastore, DNS zone, or address range. Environment-specific values are injected through variables and example configuration files.
