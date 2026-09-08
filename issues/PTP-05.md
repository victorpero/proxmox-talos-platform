## Objective

Provision and bootstrap a functional Talos Kubernetes cluster on Terraform-managed Proxmox VMs.

## Scope

- Apply role-specific Talos machine configuration to declared VMs.
- Bootstrap the Kubernetes control plane through the Talos API.
- Retrieve kubeconfig and talosconfig as sensitive generated artifacts.
- Support a minimal development topology and an HA-oriented reference topology.
- Add cluster health gates for Talos services, etcd, Kubernetes nodes, and API readiness.
- Expose stable cluster metadata for later platform components.
- Make repeated apply operations converge without re-bootstrap side effects.

## Non-goals

- Installing ingress, load balancing, GitOps, monitoring, or applications.
- Claiming HA for a topology that lacks the required control-plane quorum.
- Storing generated access credentials in the repository.

## Acceptance criteria

- [ ] A clean apply can progress from Proxmox VMs to a Ready Kubernetes cluster.
- [ ] Control-plane bootstrap is executed exactly when required.
- [ ] All expected nodes reach healthy Talos and Kubernetes states.
- [ ] kubeconfig and talosconfig are treated as sensitive artifacts.
- [ ] Re-running the workflow with unchanged inputs is convergent.
- [ ] Development and HA-oriented reference topologies are documented distinctly.
- [ ] Failure messages make unreachable or unhealthy nodes diagnosable.

## Dependencies

- PTP-04

## Suggested verification

- Bootstrap from an empty isolated Proxmox test environment.
- Run Talos health checks and `kubectl get nodes`.
- Re-run Terraform with no input changes and confirm no destructive churn.
- Remove and recreate one worker and verify the supported replacement path.

## Affected areas

Talos bootstrap, Kubernetes control plane, Terraform orchestration, generated access artifacts, and health validation.
