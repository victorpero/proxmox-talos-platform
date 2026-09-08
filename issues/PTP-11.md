## Objective

Add useful observability for Proxmox-backed Talos Kubernetes without turning the showcase into an application-specific monitoring stack.

## Scope

- Deploy a Kubernetes monitoring stack with Prometheus-compatible metrics and Grafana dashboards.
- Collect Kubernetes control-plane, node, workload, and ingress health signals.
- Integrate Talos metrics supported by the chosen version.
- Evaluate a Proxmox exporter or API-based host metrics path and document its credential model.
- Define alerts for node unavailability, control-plane degradation, resource saturation, failed GitOps reconciliation, and ingress failure.
- Keep dashboard and alert labels bounded and portable.
- Add runbook links for actionable alerts.

## Non-goals

- Monitoring a private production environment.
- Publishing real hostnames, addresses, or historical metrics.
- Adding application business metrics.

## Acceptance criteria

- [ ] Core cluster, node, ingress, and GitOps health is visible from the monitoring stack.
- [ ] Talos health metrics are integrated or their limitation is explicitly documented.
- [ ] Proxmox host metrics use a least-privilege access model if enabled.
- [ ] Alerts cover availability and saturation without excessive cardinality.
- [ ] Dashboards contain no private environment identifiers.
- [ ] At least one simulated failure produces an actionable alert.
- [ ] Monitoring deployment is reconciled through Flux.

## Dependencies

- PTP-09
- PTP-10

## Suggested verification

- Drain or stop an isolated worker and observe the expected health signals.
- Break a test Flux reconciliation and confirm alerting.
- Generate ingress traffic and inspect latency/error metrics.
- Review dashboards and exported artifacts for private identifiers.

## Affected areas

Prometheus-compatible monitoring, Grafana, Talos metrics, Proxmox metrics, alerts, dashboards, and runbooks.
