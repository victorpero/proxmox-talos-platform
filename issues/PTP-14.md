## Objective

Complete the public presentation of the project and verify that the repository demonstrates the full infrastructure lifecycle without exposing another environment.

## Scope

- Produce final architecture, component ownership, network-flow, security-boundary, and recovery diagrams.
- Document bootstrap from a clean workstation through Proxmox provisioning, Talos cluster creation, Flux reconciliation, ingress, and monitoring.
- Add a concise technology decision record for Terraform, Ansible, Talos, Flux, MetalLB, and Traefik ownership.
- Include example command sequences and expected verification output.
- Document known limitations and intentionally unsupported scenarios.
- Verify repository history and current files contain no copied private infrastructure values or credentials.
- Run a complete acceptance pass using the public reference configuration.

## Non-goals

- Turning the repository into documentation for a private homelab.
- Publishing screenshots containing private hostnames, addresses, dashboards, or credentials.
- Adding unrelated application workloads only to increase repository size.

## Acceptance criteria

- [ ] A new reader can understand the architecture and tool ownership from the README and diagrams.
- [ ] A clean reference bootstrap is documented end to end.
- [ ] Terraform, Ansible, Talos, Kubernetes, Flux, networking, security, observability, and recovery are all represented.
- [ ] The repository contains only portable examples and documentation-safe identifiers.
- [ ] CI passes from a clean checkout.
- [ ] Recovery and failure-path evidence is linked from the documentation.
- [ ] Known limitations are explicit and technically accurate.
- [ ] The repository is suitable to pin on a public GitHub profile.

## Dependencies

- PTP-01
- PTP-02
- PTP-03
- PTP-04
- PTP-05
- PTP-06
- PTP-07
- PTP-08
- PTP-09
- PTP-10
- PTP-11
- PTP-12
- PTP-13

## Suggested verification

- Follow the documentation from a clean workstation or isolated test environment.
- Run every documented validation command.
- Review repository history and rendered docs for sensitive identifiers.
- Have the architecture reviewed without relying on context outside the repository.

## Affected areas

README, architecture diagrams, decision records, runbooks, security review, acceptance evidence, and public portfolio presentation.
