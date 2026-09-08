## Objective

Make Flux the continuous-reconciliation layer for Kubernetes platform components and example workloads.

## Scope

- Define Flux bootstrap prerequisites without committing deployment credentials.
- Establish a clear directory and Kustomization/HelmRelease hierarchy.
- Order namespaces, controllers, networking, observability, and applications through explicit dependencies.
- Add health checks and reconciliation timeouts.
- Define environment overlays without copying private cluster values.
- Document image update automation as an optional extension rather than a required bootstrap dependency.
- Keep Terraform responsible for cluster creation and Flux responsible for in-cluster desired state.

## Non-goals

- Making Terraform manage every Kubernetes application object.
- Committing Git deploy credentials.
- Coupling the reference repository to a private Git server or DNS zone.

## Acceptance criteria

- [ ] Flux can bootstrap against a clean reference cluster with external credentials.
- [ ] Platform components reconcile in a deterministic dependency order.
- [ ] Drift in a managed test resource is corrected automatically.
- [ ] Terraform and Flux ownership boundaries are documented and non-overlapping.
- [ ] Environment overlays contain only portable configuration.
- [ ] Reconciliation failures surface clear status and useful events.
- [ ] Git credentials remain external to the repository.

## Dependencies

- PTP-05
- PTP-08

## Suggested verification

- Bootstrap Flux on a clean test cluster.
- Modify a managed object manually and confirm reconciliation restores desired state.
- Suspend and resume a Kustomization and inspect health behavior.
- Review the repository for accidentally committed deployment credentials.

## Affected areas

Flux, Kubernetes repository structure, GitOps ownership, health checks, and environment overlays.
