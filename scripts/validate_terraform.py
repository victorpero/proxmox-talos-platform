#!/usr/bin/env python3
"""Validate staged Terraform in isolation, without local state or credentials."""

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
        for name in ('dev', 'prod'):
            print(f'Validating {name} example with mocked, plan-only tests.', flush=True)
            terraform('test', f'-var-file=environments/{name}/platform.example.tfvars')
    print('Terraform provider validation and both environment test suites passed.')


if __name__ == '__main__':
    main()
