## Objective

Establish a public, sanitized repository foundation for a portable Proxmox → Talos → Kubernetes reference platform.

## Scope

- Create the permanent `main` and `dev` branches and use `feature/*` branches for implementation work.
- Establish the repository layout for Terraform, Ansible, Kubernetes, documentation, CI, and issue planning.
- Add an MIT license, `.gitignore`, public-repository security rules, and documentation-only environment examples.
- Define clear ownership boundaries: Terraform manages Proxmox guest infrastructure, Talos tooling manages Talos machines, Ansible manages Proxmox-side baseline and validation, and Flux manages Kubernetes resources.
- Ensure every committed hostname, address, domain, datastore name, and topology example is fictional and portable.
- Add initial CI placeholders for formatting, validation, linting, and secret detection.

## Non-goals

- Provisioning a real cluster.
- Importing values or state from any existing homelab.
- Committing credentials, private keys, kubeconfig, talosconfig, Terraform state, or real infrastructure identifiers.

## Acceptance criteria

- [ ] The repository is public under `victorpero/proxmox-talos-platform`.
- [ ] `main` and `dev` exist remotely and the documented branch workflow is clear.
- [ ] The documented directory structure exists and has concise ownership documentation.
- [ ] Committed network examples use documentation-only address ranges.
- [ ] No real IP address, DNS name, MAC address, storage identifier, token, or secret from another environment is present.
- [ ] The README explains the architecture, scope, portability model, and security boundary.
- [ ] Initial repository validation can run from a clean checkout.

## Dependencies

None.

## Suggested verification

- Review the repository from a fresh clone.
- Search committed content for environment-specific identifiers and credentials.
- Confirm all example addresses and domains are explicitly documentation-only values.
- Verify the branch topology and README links.

## Affected areas

Repository structure, documentation, security boundary, CI foundation, and public presentation.
