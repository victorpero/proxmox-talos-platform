## Objective

Prove that the platform can be reconstructed from declared infrastructure and documented recovery procedures, and identify state that requires separate backup.

## Scope

- Define recovery boundaries for Proxmox VMs, Talos configuration, Kubernetes control-plane state, GitOps state, and application data.
- Create a controlled destroy/rebuild test for non-production infrastructure.
- Document Talos control-plane recovery and worker replacement procedures.
- Reconcile Kubernetes platform components through Flux after recovery.
- Distinguish declarative configuration from stateful data requiring application-aware backup.
- Measure infrastructure rebuild and cluster recovery time during a test.
- Record manual steps, dependencies, and failure points.

## Non-goals

- Claiming zero-data-loss recovery without an application backup design.
- Treating Terraform state, VM disks, PVCs, or Git alone as complete backup.
- Running destructive recovery tests against an unrelated environment.

## Acceptance criteria

- [ ] A documented non-production rebuild test can recreate the declared Proxmox VM topology.
- [ ] Talos/Kubernetes recovery reaches a healthy cluster using the documented procedure.
- [ ] Flux restores platform desired state after cluster recovery.
- [ ] Stateful data boundaries and required backup mechanisms are explicit.
- [ ] Recovery timing and manual steps are recorded.
- [ ] Worker replacement is tested independently from full-cluster recovery.
- [ ] Recovery documentation contains no private infrastructure identifiers.

## Dependencies

- PTP-05
- PTP-09
- PTP-11
- PTP-12

## Suggested verification

- Destroy and reconstruct an isolated reference cluster.
- Replace one worker independently.
- Validate cluster health before and after Flux reconciliation.
- Record elapsed time and compare with the documented recovery objectives.

## Affected areas

Terraform rebuild workflow, Talos recovery, Kubernetes recovery, Flux reconciliation, backup boundaries, and runbooks.
