## Objective

Harden the public reference platform with explicit secret handling, least privilege, network boundaries, and secure automation defaults.

## Scope

- Define a secrets workflow compatible with GitOps, such as SOPS with externally held private key material.
- Keep Proxmox credentials, Talos machine secrets, kubeconfig, talosconfig, DNS credentials, and encryption private keys outside committed source.
- Document Terraform state sensitivity and secure backend expectations.
- Apply least-privilege Kubernetes RBAC to platform automation identities.
- Add default-deny or scoped NetworkPolicies where platform components support them safely.
- Harden GitHub Actions permissions and pin third-party actions.
- Add secret scanning and infrastructure security checks.
- Document the security trust boundaries between GitHub, Proxmox, Talos, Kubernetes, and operators.

## Non-goals

- Publishing real encrypted production secrets as showcase data.
- Claiming that encryption alone makes arbitrary secret publication appropriate.
- Building a custom identity provider.

## Acceptance criteria

- [ ] No plaintext credential or private key is committed.
- [ ] The documented secret workflow can bootstrap in an isolated environment.
- [ ] Automation identities use documented least-privilege permissions.
- [ ] Terraform state handling is treated as sensitive.
- [ ] Security scans run in CI with documented failure behavior.
- [ ] Network and RBAC boundaries do not rely on private environment assumptions.
- [ ] A concise threat/trust-boundary section exists in the documentation.

## Dependencies

- PTP-02
- PTP-05
- PTP-09

## Suggested verification

- Run secret scanning against the full Git history before first release.
- Inspect Kubernetes RBAC and NetworkPolicies in the test cluster.
- Validate the secret bootstrap process from a fresh operator workstation.
- Review CI workflow permissions and action pinning.

## Affected areas

Secrets, Terraform state, Kubernetes RBAC, NetworkPolicies, CI permissions, GitOps, and security documentation.
