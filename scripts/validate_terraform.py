#!/usr/bin/env python3
"""Validate staged Terraform in isolation, without local state or credentials."""

import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    paths = subprocess.check_output(['git', 'ls-files', '-z', 'terraform/'])
    with tempfile.TemporaryDirectory(prefix='ptp-terraform-') as temporary:
        root = Path(temporary)
        subprocess.run(
            ['git', 'checkout-index', '-z', '--stdin', f'--prefix={root}/'],
            input=paths, check=True,
        )
        cli_config = root / 'terraform.rc'
        cli_config.touch()
        # Do not inherit TF_VAR_*, TF_CLI_ARGS*, provider credentials, or backend
        # settings. Use the normal registry and the committed dependency lock.
        environment = {
            name: os.environ[name]
            for name in ('PATH', 'TMPDIR', 'SYSTEMROOT', 'SSL_CERT_FILE', 'SSL_CERT_DIR')
            if name in os.environ
        }
        environment.update({
            'TF_CLI_CONFIG_FILE': str(cli_config),
            'TF_IN_AUTOMATION': '1',
            'CHECKPOINT_DISABLE': '1',
        })

        def terraform(*arguments):
            subprocess.run(
                ['terraform', *arguments, '-no-color'],
                cwd=root / 'terraform', env=environment, check=True,
            )

        terraform('init', '-backend=false', '-input=false', '-lockfile=readonly')
        terraform('validate')

        def test_example(name, *filters):
            plans = {}
            command = ['terraform', 'test', '-json', '-verbose', *filters,
                       f'-var-file=environments/{name}/platform.example.tfvars']
            with subprocess.Popen(command, cwd=root / 'terraform', env=environment,
                                  stdout=subprocess.PIPE, text=True) as process:
                for line in process.stdout:
                    event = json.loads(line)
                    if event.get('type') == 'test_plan':
                        if event.get('@testfile') == 'tests/vms.tftest.hcl':
                            plans[event['@testrun']] = event['test_plan'].get('resource_changes', [])
                    else:
                        print(event.get('@message', ''), flush=True)
                        if event.get('type') == 'diagnostic':
                            print(event['diagnostic'].get('detail', ''), flush=True)
                if process.wait():
                    raise subprocess.CalledProcessError(process.returncode, command)

            baseline = plans['module_vm_contract']
            if not baseline or baseline != plans['unchanged_inputs_preserve_metadata']:
                raise RuntimeError(f'{name}: repeated VM plans differ')
            if any(item['change']['actions'] != ['create'] for item in baseline):
                raise RuntimeError(f'{name}: a fresh VM plan must only create resources')
            expanded = {item['address']: item for item in plans['added_node_preserves_existing_identity']}
            if len(expanded) != len(baseline) + 1 or any(
                    expanded.get(item['address']) != item for item in baseline):
                raise RuntimeError(f'{name}: adding a VM changed an existing resource plan')
            reduced = plans['single_control_plane_vm']
            if len(reduced) != 1 or reduced[0] not in baseline:
                raise RuntimeError(f'{name}: reducing the topology changed the retained VM')
            print(f'{name}: identical repeated resource plans; adding/removing nodes preserves retained VM plans.')

        for name in ('dev', 'prod'):
            print(f'Validating {name} example with mocked, plan-only tests.', flush=True)
            test_example(name)
        print('Validating the single-node example with mocked VM plans.', flush=True)
        test_example('single-node', '-filter=tests/vms.tftest.hcl')
    print('Terraform provider validation and all environment test suites passed.')


if __name__ == '__main__':
    main()
