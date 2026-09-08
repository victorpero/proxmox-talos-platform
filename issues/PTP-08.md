## Objective

Establish portable bare-metal-style Kubernetes networking with MetalLB and Traefik using environment-injected address pools.

## Scope

- Install MetalLB through declarative Kubernetes manifests or Helm releases managed in the GitOps layout.
- Define address pools entirely from environment configuration.
- Install Traefik as the reference ingress controller.
- Expose a small test service through a LoadBalancer and ingress route.
- Add health checks and explicit dependency ordering.
- Document L2 assumptions, ARP/NDP behavior, and limitations for routed or VLAN-separated networks.
- Ensure all committed addresses remain documentation-only examples.

## Non-goals

- Reusing any real load-balancer pool.
- Automating public DNS.
- Adding application-specific ingress policy.

## Acceptance criteria

- [ ] MetalLB assigns an address from the configured environment pool.
- [ ] Traefik obtains a reachable LoadBalancer service in the test environment.
- [ ] A test application is reachable through the reference ingress path.
- [ ] Address pools are parameterized and contain no real environment values in source.
- [ ] Networking components have readiness checks and declarative configuration.
- [ ] L2 assumptions and alternative network models are documented.
- [ ] Removing the test application leaves no orphaned application-specific resources.

## Dependencies

- PTP-05

## Suggested verification

- Deploy the networking stack to an isolated cluster.
- Inspect MetalLB speaker/controller health and service assignment.
- Resolve and request the test ingress endpoint.
- Change the fictional example pool in a separate environment and verify no code changes are required.

## Affected areas

Kubernetes networking, MetalLB, Traefik, GitOps layout, environment configuration, and documentation.
