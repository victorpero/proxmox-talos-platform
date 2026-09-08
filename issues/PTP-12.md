## Objective

Build a fast, reproducible pull-request pipeline that validates Terraform, Ansible, Kubernetes manifests, security posture, and repository hygiene.

## Scope

- Run Terraform formatting, initialization without deployment, validation, and linting.
- Run `ansible-lint` and YAML validation.
- Validate Kubernetes YAML/Helm/Kustomize output against schemas where practical.
- Run infrastructure and container/configuration security scanning where relevant.
- Run secret detection across changed content and enforce the public-repository boundary.
- Pin action versions and use least-privilege workflow permissions.
- Add a non-destructive Terraform plan workflow for an explicitly configured test environment when credentials are available.
- Keep credential-requiring jobs opt-in and protected.

## Non-goals

- Automatically applying infrastructure from every pull request.
- Exposing plan files or logs containing sensitive values.
- Depending on a private runner for basic static validation.

## Acceptance criteria

- [ ] Pull requests run Terraform format/validate/lint checks.
- [ ] Pull requests run Ansible and YAML quality checks.
- [ ] Rendered Kubernetes configuration is validated.
- [ ] Secret detection blocks committed sensitive material.
- [ ] Workflow permissions are explicit and minimal.
- [ ] Credential-free validation works on standard hosted runners.
- [ ] Any credentialed plan job is protected, redacted, and non-destructive.

## Dependencies

- PTP-02
- PTP-06
- PTP-09
- PTP-10

## Suggested verification

- Introduce controlled formatting, schema, lint, and fake-secret failures on a test branch.
- Inspect workflow permissions.
- Review logs for accidental sensitive output.
- Confirm a clean checkout passes every credential-free validation job.

## Affected areas

GitHub Actions, Terraform validation, Ansible linting, Kubernetes validation, secret scanning, and repository security.
