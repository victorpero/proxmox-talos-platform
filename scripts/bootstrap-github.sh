#!/usr/bin/env bash
set -euo pipefail

REPO="victorpero/proxmox-talos-platform"
DESCRIPTION="Public reference platform for provisioning Talos Kubernetes on Proxmox with Terraform, Ansible, Flux, Traefik, and MetalLB."

command -v gh >/dev/null 2>&1 || {
  echo "GitHub CLI (gh) is required."
  exit 1
}

gh auth status >/dev/null

repo_exists=false
if gh repo view "$REPO" >/dev/null 2>&1; then
  repo_exists=true
fi

if [ "$repo_exists" = false ]; then
  if [ ! -d .git ]; then
    git init -b main
  fi

  git add .
  if ! git diff --cached --quiet; then
    git commit -m "chore: bootstrap public Proxmox Talos platform"
  fi

  gh repo create "$REPO" \
    --public \
    --description "$DESCRIPTION" \
    --source=. \
    --remote=origin \
    --push
else
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/${REPO}.git"
  fi
fi

if ! git show-ref --verify --quiet refs/heads/dev; then
  git branch dev main
fi
git push -u origin main
git push -u origin dev

gh label create 'type: infrastructure' --repo "$REPO" --color 5319e7 --description 'Platform, delivery, or operations work' --force
gh label create 'type: feature' --repo "$REPO" --color a2eeef --description 'New platform capability' --force
gh label create 'type: maintenance' --repo "$REPO" --color c5def5 --description 'Quality, process, or internal improvement' --force
gh label create 'type: documentation' --repo "$REPO" --color 0075ca --description 'Documentation and public presentation' --force
gh label create 'area: repository' --repo "$REPO" --color 6f42c1 --description 'Repository structure and project conventions' --force
gh label create 'area: terraform' --repo "$REPO" --color 623ce4 --description 'Terraform providers, modules, state, and environments' --force
gh label create 'area: proxmox' --repo "$REPO" --color e57000 --description 'Proxmox infrastructure and VM lifecycle' --force
gh label create 'area: talos' --repo "$REPO" --color 00a4ef --description 'Talos Linux image and machine configuration' --force
gh label create 'area: kubernetes' --repo "$REPO" --color 326ce5 --description 'Kubernetes cluster lifecycle and control plane' --force
gh label create 'area: ansible' --repo "$REPO" --color ee0000 --description 'Ansible baseline, inventory, and validation' --force
gh label create 'area: networking' --repo "$REPO" --color 1d76db --description 'Load balancing, ingress, and network behavior' --force
gh label create 'area: gitops' --repo "$REPO" --color 006b75 --description 'Flux and continuous reconciliation' --force
gh label create 'area: security' --repo "$REPO" --color b60205 --description 'Secrets, RBAC, hardening, and trust boundaries' --force
gh label create 'area: observability' --repo "$REPO" --color fbca04 --description 'Metrics, dashboards, alerts, and platform health' --force
gh label create 'area: ci' --repo "$REPO" --color 0052cc --description 'Continuous integration and repository validation' --force
gh label create 'area: disaster-recovery' --repo "$REPO" --color d876e3 --description 'Rebuild, recovery, and backup boundaries' --force
gh label create 'area: documentation' --repo "$REPO" --color 0e8a16 --description 'Architecture docs, runbooks, and portfolio presentation' --force
gh label create 'priority: p0' --repo "$REPO" --color d93f0b --description 'Foundational or release-blocking' --force
gh label create 'priority: p1' --repo "$REPO" --color fbca04 --description 'Important follow-up work' --force
gh label create 'priority: p2' --repo "$REPO" --color 0e8a16 --description 'Useful enhancement' --force

existing_titles="$(gh issue list --repo "$REPO" --state all --limit 200 --json title --jq '.[].title')"

create_issue_if_missing() {
  local title="$1"
  local body_file="$2"
  shift 2

  if printf '%s\n' "$existing_titles" | grep -Fqx "$title"; then
    echo "Issue already exists: $title"
    return
  fi

  local args=()
  local label
  for label in "$@"; do
    args+=(--label "$label")
  done

  gh issue create --repo "$REPO" --title "$title" --body-file "$body_file" "${args[@]}"
}

create_issue_if_missing 'PTP-01 — Repository & platform bootstrap' issues/PTP-01.md 'type: infrastructure' 'area: repository' 'priority: p0'
create_issue_if_missing 'PTP-02 — Terraform provider & environment model' issues/PTP-02.md 'type: infrastructure' 'area: terraform' 'priority: p0'
create_issue_if_missing 'PTP-03 — Reusable Proxmox VM module' issues/PTP-03.md 'type: feature' 'area: proxmox' 'priority: p0'
create_issue_if_missing 'PTP-04 — Talos image & machine configuration' issues/PTP-04.md 'type: feature' 'area: talos' 'priority: p0'
create_issue_if_missing 'PTP-05 — Talos Kubernetes cluster provisioning' issues/PTP-05.md 'type: feature' 'area: kubernetes' 'priority: p0'
create_issue_if_missing 'PTP-06 — Ansible Proxmox baseline & preflight' issues/PTP-06.md 'type: infrastructure' 'area: ansible' 'priority: p1'
create_issue_if_missing 'PTP-07 — Dynamic inventory & infrastructure validation' issues/PTP-07.md 'type: feature' 'area: ansible' 'priority: p1'
create_issue_if_missing 'PTP-08 — Kubernetes networking with MetalLB & Traefik' issues/PTP-08.md 'type: feature' 'area: networking' 'priority: p0'
create_issue_if_missing 'PTP-09 — Flux GitOps foundation' issues/PTP-09.md 'type: feature' 'area: gitops' 'priority: p0'
create_issue_if_missing 'PTP-10 — Secrets, RBAC & platform hardening' issues/PTP-10.md 'type: infrastructure' 'area: security' 'priority: p0'
create_issue_if_missing 'PTP-11 — Observability & platform health' issues/PTP-11.md 'type: feature' 'area: observability' 'priority: p1'
create_issue_if_missing 'PTP-12 — CI validation & infrastructure security pipeline' issues/PTP-12.md 'type: infrastructure' 'area: ci' 'priority: p1'
create_issue_if_missing 'PTP-13 — Disaster recovery & rebuild validation' issues/PTP-13.md 'type: maintenance' 'area: disaster-recovery' 'priority: p1'
create_issue_if_missing 'PTP-14 — Architecture documentation & portfolio acceptance' issues/PTP-14.md 'type: documentation' 'area: documentation' 'priority: p1'

echo
echo "Repository bootstrap complete:"
echo "https://github.com/${REPO}"
