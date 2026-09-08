# Disaster recovery

The project includes a rebuild-oriented recovery model rather than treating configuration drift or manual repair as the primary recovery strategy.

## Recovery layers

1. Recreate Proxmox guest infrastructure from Terraform.
2. Regenerate or restore the approved Talos machine configuration material.
3. Bootstrap or recover Kubernetes control-plane state according to the chosen Talos recovery procedure.
4. Reconcile platform services and applications through Flux.
5. Restore stateful application data from application-aware backups where applicable.
6. Run automated health and acceptance checks.

## Validation

Recovery testing should measure and document:

- infrastructure reconstruction time
- cluster recovery time
- GitOps reconciliation time
- application recovery time
- unresolved manual steps

The reference repository should never imply that Terraform state, a PVC, or a VM disk alone is an application backup.
