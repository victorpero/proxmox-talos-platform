# Proxmox Talos Platform

A portable reference platform for running Talos Linux and Kubernetes on Proxmox,
with Terraform for guest infrastructure, Ansible for Proxmox operations, and Flux
for Kubernetes delivery.

**Status:** Terraform provider and environment foundation. The root configuration
initializes a pinned Proxmox provider and validates portable environment inputs.
It declares no resources or data sources and provisions no infrastructure. VM
creation, Talos bootstrap, and Kubernetes manifests remain planned work.

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
  versions.tf                  Terraform/provider constraints and local backend
  providers.tf                 Proxmox provider with TLS verification
  variables.tf                 Validated environment input contract
  tests/                       Mocked plan-only input tests
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

The `*.example.tfvars` files are validated inputs for the single [Terraform root](terraform).
Both examples use the same `platform` object schema; select one explicitly with
`-var-file`. They describe IPv4 topologies without creating VMs. No example values
are defaults. Keep real variable files and inventories outside this checkout.

## Terraform provider and environment model

The root requires Terraform `>= 1.13.3, < 1.14.0` (CI uses 1.13.3) and pins
[`bpg/proxmox` 0.112.0](https://github.com/bpg/terraform-provider-proxmox/releases/tag/v0.112.0).
This provider covers the planned Proxmox guest lifecycle through one provider
configuration; aliases and extra modules are unnecessary until separate endpoints
or ownership boundaries require them. Its pre-1.0 upgrades are deliberate PRs:
review upstream changes, update the constraint and lockfile, and run both example
suites before merging. The committed lockfile includes Linux AMD64 and macOS
AMD64/ARM64 checksums. To refresh it after a reviewed version change:

```bash
terraform -chdir=terraform init -backend=false -upgrade
terraform -chdir=terraform providers lock \
  -platform=linux_amd64 -platform=darwin_amd64 -platform=darwin_arm64
```

The [provider configuration](terraform/providers.tf) sets TLS verification on and
minimum TLS 1.3 explicitly. Use a trusted certificate chain; no insecure toggle is
exposed. `platform.proxmox_endpoint` is the HTTPS server origin ending in `/`,
for example `https://pve.example.com:8006/`, **without `/api2/json`**. Authentication
is supplied through `PROXMOX_VE_API_TOKEN` by the operator's secret store or runtime;
there is no credential Terraform variable, example token, password, or SSH block.
See the [pinned provider authentication reference](https://github.com/bpg/terraform-provider-proxmox/blob/v0.112.0/docs/index.md).
No credentials are needed for initialization, validation, or mocked tests. Future
VM operations will need a scoped identity; permissions and API connectivity have
not been tested against a live Proxmox environment.

All fields below are required except `nodes.*.vlan_id`. The exact types and error
messages live in [variables.tf](terraform/variables.tf).

| Field within `platform` | Contract |
| --- | --- |
| `cluster_name` | Lowercase DNS label, 1-63 characters, starts with a letter |
| `proxmox_endpoint` | HTTPS origin with hostname or IPv4 host and optional port 1-65535; no embedded credentials or paths |
| `network.cidr` | Canonical IPv4 network, prefix 1-30; IPv6/dual-stack is deferred |
| `network.gateway` | Usable address within that network |
| `network.dns_servers` | Nonempty, distinct IPv4 resolver addresses; may be outside the node subnet |
| `network.dns_domain` | Lowercase DNS domain, valid labels, at most 253 characters, no trailing dot |
| `nodes` | Map keyed by unique lowercase node DNS labels; 1, 3, or 5 control-plane nodes and at least one worker |
| `nodes.*.role` | `control-plane` or `worker` |
| `nodes.*.target_node` | Explicit Proxmox target node, 1-63 characters, starts with a letter |
| `nodes.*.datastore` / `bridge` | Explicit storage and bridge identifiers, 1-64 / 1-15 characters, start with a letter |
| `nodes.*.vlan_id` | Omit or set null for untagged; otherwise integer 1-4094 |
| `nodes.*.address` | Distinct usable IPv4 host in the subnet, excluding the gateway |
| `nodes.*.cpu` | Integer cores, 2-128 |
| `nodes.*.memory_mib` | 1024 MiB increments; control-plane minimum 4096, worker minimum 2048, maximum 1048576 |
| `nodes.*.disk_gib` | Integer GiB, 10-65536 |
| `metallb_pool.start` / `end` | Inclusive, ordered usable IPv4 range in the subnet; cannot contain gateway, DNS, or node addresses |

Resource bounds are reference-platform guardrails, not a host capacity check.
Names allow letters, digits, and hyphens; datastore and bridge names also allow
underscores and dots. All addresses are declarations only: validation cannot check
DHCP reservations, existing host/storage/bridge names, free capacity, or network
reachability. The prod example spreads three control-plane nodes across three
fictional hosts, but topology validation alone does not establish availability.
Image selection, VM IDs, tags, and guest resources arrive with PTP-03/PTP-04.

### State isolation and backend choice

Local state is the default for individual development. State and saved plans must
be treated as sensitive even when outputs are marked sensitive. Keep separate
state paths **and** Terraform data directories for each environment. A variable
file alone does not select or isolate state. Never switch dev/prod inputs against
the same initialized state. The following Bash commands create only local metadata
and run a plan for the resource-free foundation:

```bash
umask 077
platform_state_dir="$(mktemp -d)"
export TF_DATA_DIR="$platform_state_dir/terraform-data"
terraform -chdir=terraform init -input=false -lockfile=readonly \
  -backend-config="path=$platform_state_dir/dev.tfstate"
terraform -chdir=terraform validate
terraform -chdir=terraform plan -input=false \
  -var-file=environments/dev/platform.example.tfvars
unset TF_DATA_DIR
```

The expected plan is `No changes`. For prod, use a new private directory, a
`prod.tfstate` path, and the prod variable file. For persistent development, replace
`mktemp -d` with a durable private directory outside this checkout, maintain backups,
and retain the environment's path association. Do not apply the fictional examples.

For collaboration, choose a remote backend with locking, encryption in transit and
at rest, restricted access, versioning, and a tested recovery process. Terraform's
backend type cannot be chosen with an input variable. Supply a local, ignored
`terraform/backend_override.tf` containing a `terraform` block with the chosen
`backend` block; Terraform override semantics replace the default local backend.
Supply non-secret backend settings from an external `*.backend.hcl` with
`terraform init -backend-config=/absolute/path/to/environment.backend.hcl` and use
the backend's runtime credential mechanism. No cloud account or backend service is
required by this repository. See [Terraform backend configuration](https://developer.hashicorp.com/terraform/language/backend)
and [override file behavior](https://developer.hashicorp.com/terraform/language/files/override).

Back up existing state and verify the source and destination before explicitly
running `terraform init -migrate-state`. Use `-reconfigure` only when intentionally
reinitializing backend settings without moving state. Do not mix those flags.
Backend caches can retain configuration, and plans/state can contain secrets:
keep the override, backend settings, data directory, state, backups, and plan files
private. CI rejects tracked backend override/settings files and never initializes
a deployment backend.

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

Prerequisites: Git, Bash, Python 3.10 or newer with `venv`, and Terraform 1.13.3
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
opens ignored local notes. Terraform provider checks copy staged Terraform files
into a temporary directory, ignore local backend overrides and variable files,
and clear inherited provider credentials and Terraform CLI settings. Terraform formatting, YAML linting, and
shell syntax checks read tracked working files; keep staged content and working
files aligned.

The same entry point runs in GitHub Actions without infrastructure credentials:

- Required tracked directories, README file links, JSON syntax, LF endings, and trailing whitespace.
- Root README as the only tracked Markdown file; generated access files, keys, state, and non-example variable files rejected.
- Documentation address ranges, omitted MAC addresses, and baseline detection of common credential patterns without printing matched values.
- Regression checks, Terraform formatting, YAML linting, and Bash syntax.
- Locked provider initialization with `-backend=false`, provider schema validation,
  and mocked plan-only tests of both examples and invalid inputs. Provider downloads
  need network access; the tests do not contact Proxmox or create resources.

For the dependency-free publication check alone, run
`python3 scripts/validate_repository.py`. Ansible linting, Kubernetes schema checks,
and a dedicated secret scanner will be introduced with the corresponding
implementations and PTP-12. The bootstrap
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
the repository foundation. [PTP-02](https://github.com/victorpero/proxmox-talos-platform/issues/2)
adds the provider and environment contract. Follow-up issues cover VM modules,
Talos images and cluster bootstrap, Ansible baseline and inventory, networking,
Flux, security, observability, CI hardening, recovery, and final acceptance.

Released under the [MIT license](LICENSE).
