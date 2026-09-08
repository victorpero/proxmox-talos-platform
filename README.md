# Proxmox Talos Platform

A portable reference platform for running Talos Linux and Kubernetes on Proxmox,
with Terraform for guest infrastructure, Ansible for Proxmox operations, and Flux
for Kubernetes delivery.

**Status:** repository foundation. The directories and examples establish the
platform boundary; providers, VM provisioning, Talos bootstrap, and Kubernetes
manifests are planned work. Nothing in this bootstrap provisions infrastructure.

## Architecture and ownership

```text
Proxmox hosts ← Ansible baseline, preflight, and validation
    │
Terraform guest infrastructure
    ├── Talos control-plane VMs
    └── Talos worker VMs
            │
       Talos API tooling
            │
        Kubernetes
            │
           Flux
            ├── MetalLB and Traefik
            ├── Monitoring
            └── Applications
```

| Component | Owns | Boundary |
| --- | --- | --- |
| Terraform | Proxmox guest creation, compute, disks, and networking declarations | Does not configure Proxmox hosts or reconcile workloads |
| Talos tooling | Machine configuration, node lifecycle, and Kubernetes bootstrap | Talos machines are immutable and managed through their API |
| Ansible | Proxmox host baseline, inventory, preflight, and operational validation | Does not configure Talos nodes over SSH |
| Flux | Kubernetes add-ons and application reconciliation | Does not provision Proxmox guests or bootstrap Talos |
| MetalLB / Traefik | Service load-balancer addresses / ingress | Delivered through Flux once the cluster exists |

Talos configuration ownership remains with Talos tooling even if a later Terraform
provider integration coordinates its lifecycle. Each layer has one configuration
owner to avoid competing sources of truth.

## Repository layout

```text
.github/
  workflows/                   Repository validation
terraform/
  modules/proxmox-vm/           Reusable guest module placeholder
  environments/dev/            Small documentation topology
  environments/prod/           Multi-node documentation topology
ansible/
  inventory.example.yml        Fictional Proxmox inventory
  roles/proxmox/               Host baseline placeholder
  playbooks/                   Preflight and validation placeholders
kubernetes/
  flux/                        GitOps bootstrap placeholder
  traefik/                     Ingress placeholder
  metallb/                     Load-balancer placeholder
  monitoring/                  Observability placeholder
  applications/                Workload placeholder
docs/                          Reserved for future non-Markdown diagrams
issues/                        Local planning workspace; public planning is on GitHub
scripts/                       Local and CI validation entry points
tests/                         Publication-boundary regression checks
```

Empty areas contain `.gitkeep` files so the layout survives a clean checkout.
The root `README.md` is the sole published Markdown document. Architecture,
security, contribution, and recovery guidance live here; work is tracked in
[GitHub issues](https://github.com/victorpero/proxmox-talos-platform/issues).

## Portability and examples

This is a fictional reference environment. Never copy hostnames, domains,
addresses, MAC addresses, datastore names, bridge names, VLANs, topology details,
or credentials from an existing environment into committed content.

- [Development example](terraform/environments/dev/platform.example.tfvars): one control-plane node and one worker.
- [Production-shaped example](terraform/environments/prod/platform.example.tfvars): three control-plane nodes and two workers; availability is not yet implemented or tested.
- [Ansible inventory example](ansible/inventory.example.yml): `pve.example.com`, with no credentials or access settings.

IPv4 examples use `192.0.2.0/24`, `198.51.100.0/24`, or `203.0.113.0/24` as
specified in [RFC 5737](https://www.rfc-editor.org/rfc/rfc5737). IPv6 examples may
use `2001:db8::/32`. Infrastructure DNS examples use `example.com`, `example.net`,
or `example.org` and their subdomains.

The `*.example.tfvars` files document the intended input shape. They are not
runnable Terraform environments yet. Later implementations must expose host,
bridge, datastore, network, and cluster settings through explicit inputs. Keep
real variable files and inventories outside this checkout and inject credentials
at runtime.

## Branch and pull request workflow

```text
feature/<issue>-<description> → dev → main
```

1. Start each feature branch from an up-to-date `dev`, for example
   `feature/ptp-01-repository-bootstrap`.
2. Keep the change scoped to its issue. Stage intended files explicitly, inspect
   `git diff --cached`, and run the validation below.
3. Open a pull request from the feature branch into `dev`, referencing its issue
   and recording validation results. Review and pass checks before merging.
4. Promote reviewed integration changes through a separate `dev` → `main` pull
   request. `main` represents the reviewed public reference release.

CI rejects pull requests into `main` unless they come from this repository's
`dev` branch. Dependency update pull requests target `dev`. Repository branch
protection should require pull requests and successful checks; workflow checks
alone do not prevent direct pushes.

## Validation from a clean checkout

Prerequisites: Git, Bash, Python 3.9 or newer with `venv`, and Terraform 1.13.3
(the version used by CI). Install Terraform using the
[official installation instructions](https://developer.hashicorp.com/terraform/install).

```bash
git clone --branch dev https://github.com/victorpero/proxmox-talos-platform.git
cd proxmox-talos-platform
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
bash scripts/validate.sh
```

After editing, stage intended files before validation. The publication check reads
Git's staged blobs, so it checks exactly what a commit would publish and never
opens ignored local notes. Terraform formatting, YAML linting, and shell syntax
checks read tracked working files; keep staged content and working files aligned.

The same entry point runs in GitHub Actions without infrastructure credentials:

- Required tracked directories, README file links, JSON syntax, LF endings, and trailing whitespace.
- Root README as the only tracked Markdown file; generated access files, keys, state, and non-example variable files rejected.
- Documentation address ranges, omitted MAC addresses, and baseline detection of common credential patterns without printing matched values.
- Regression checks, Terraform example formatting, YAML linting, and Bash syntax.

For the dependency-free publication check alone, run
`python3 scripts/validate_repository.py`. Provider initialization and validation,
Ansible linting, Kubernetes schema checks, and a dedicated secret scanner will be
introduced with the corresponding implementations and PTP-12. The bootstrap
scanner covers common patterns, not all possible secrets or environment-specific
identifiers; review the full diff before publishing.

## Security boundary

Keep Proxmox API credentials, private encryption keys, Talos machine secrets,
kubeconfig, talosconfig, Terraform state and plans, decrypted secret files, and
real environment configuration outside version control. `.gitignore` provides
artifact exclusions; CI also rejects sensitive file types if they are force-added.

Use runtime environment variables or a secret store for credentials. Future
Proxmox automation identities must have only the privileges their resources need;
Kubernetes service accounts must also be scoped to their operations. CI uses
read-only repository permissions and action revisions pinned to commit IDs.

If a credential is published, revoke or rotate it before coordinating history
cleanup. Deleting it in a later commit does not remove it from Git history.

## Recovery model

The planned recovery sequence is guest reconstruction with Terraform, recovery
of approved Talos machine configuration and control-plane state, Flux
reconciliation, and application-aware data restoration. Recovery tests must
measure each stage and record manual steps. Terraform state, VM disks, and PVCs
alone are not application backups. Recovery procedures are not implemented yet.

## Roadmap and license

[PTP-01](https://github.com/victorpero/proxmox-talos-platform/issues/1) establishes
this foundation. Follow-up issues cover Terraform providers and VM modules,
Talos images and cluster bootstrap, Ansible baseline and inventory, networking,
Flux, security, observability, CI hardening, recovery, and final acceptance.

Released under the [MIT license](LICENSE).
