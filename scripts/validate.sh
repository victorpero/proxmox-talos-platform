#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

for tool in python3 terraform yamllint; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing validation tool: $tool. See README.md for setup."
    exit 1
  fi
done

export PYTHONDONTWRITEBYTECODE=1
python3 scripts/validate_repository.py
python3 -m unittest discover -s tests -p 'test_*.py'
terraform fmt -check -diff -recursive terraform

while IFS= read -r -d '' tracked_file; do
  case "$tracked_file" in
    *.sh) bash -n "$tracked_file" ;;
    *.yml|*.yaml) yamllint -s "$tracked_file" ;;
  esac
done < <(git ls-files -z)

echo 'Bootstrap checks passed. Provider, Ansible, and Kubernetes validation arrive with their implementations (PTP-02/PTP-06/PTP-09/PTP-12).'
