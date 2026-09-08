"""Regression checks for the publication boundary using synthetic fixtures."""

import importlib.util
import ipaddress
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / 'scripts' / 'validate_repository.py'
SPEC = importlib.util.spec_from_file_location('validation', SCRIPT)
validation = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validation)


class ContentValidationTests(unittest.TestCase):
    def test_documentation_networks_and_subnets_are_allowed(self):
        content = '192.0.2.11 198.51.100.0/24 203.0.113.4 2001:db8::1/64\n'
        self.assertEqual(validation.file_errors('README.md', content.encode()), [])

    def test_non_documentation_ipv4_addresses_are_rejected(self):
        for packed in ((10, 0, 0, 1), (172, 16, 0, 1), (192, 168, 0, 1), (8, 8, 8, 8)):
            address = '.'.join(map(str, packed))
            with self.subTest(packed=packed):
                self.assertTrue(validation.file_errors('example.txt', f'{address}\n'.encode()))

    def test_non_documentation_ipv6_addresses_are_rejected(self):
        for packed in (1, int('fd000000000000000000000000000001', 16)):
            address = str(ipaddress.IPv6Address(packed))
            self.assertTrue(validation.file_errors('example.txt', f'[{address}]\n'.encode()))

    def test_cidr_cannot_extend_outside_documentation_range(self):
        for address in ('192.0.2.0', '2001:db8::'):
            self.assertTrue(validation.file_errors('example.txt', f'{address}/{16}\n'.encode()))

    def test_non_root_markdown_is_rejected(self):
        for name in ('memory.md', 'DESIGN.md', 'PRODUCT.md', 'docs/README.md', 'notes.MD'):
            with self.subTest(name=name):
                self.assertTrue(validation.file_errors(name, b'Notes\n'))

    def test_sensitive_artifact_names_are_rejected(self):
        for name in (
            'terraform.tfstate.backup', 'server.key', 'cluster.kubeconfig',
            'talosconfig-dev', 'secrets.yml', '.env', '.env.local',
            'private.tfvars', 'private.tfvars.json', '.terraform/settings',
            'terraform/backend_override.tf', 'dev.backend.hcl',
        ):
            with self.subTest(name=name):
                self.assertTrue(validation.file_errors(name, b''))
        self.assertEqual(validation.file_errors('platform.example.tfvars', b''), [])

    def test_credentials_are_rejected_without_echoing_them(self):
        fixtures = (
            'ghp_' + 'x' * 36,
            'github_pat_' + 'x' * 60,
            'AKIA' + 'X' * 16,
            '-----BEGIN ' + 'OPENSSH PRIVATE KEY-----',
            'AGE-SECRET-' + 'KEY-' + 'X' * 20,
            'api_token = "' + 'synthetic-value"',
            'https://' + 'user:synthetic-value@pve.example.com',
        )
        for fixture in fixtures:
            with self.subTest(prefix=fixture[:4]):
                errors = validation.file_errors('example.txt', (fixture + '\n').encode())
                self.assertTrue(errors)
                self.assertNotIn(fixture, '\n'.join(errors))

    def test_mac_addresses_are_rejected(self):
        address = ':'.join(('02', '00', '00', '00', '00', '01'))
        self.assertTrue(validation.file_errors('example.txt', f'{address}\n'.encode()))

    def test_invalid_json_and_formatting_are_rejected(self):
        for name, content in (
            ('data.json', b'{\n'), ('file.txt', b'no newline'),
            ('file.txt', b'trailing \n'), ('file.txt', b'line\r\n'),
            ('file.bin', b'\xff\n'), ('file.bin', b'\x00\n'),
        ):
            self.assertTrue(validation.file_errors(name, content))


class IndexValidationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.git('init', '--quiet')
        for directory in validation.REQUIRED_DIRECTORIES:
            target = self.root / directory / '.gitkeep'
            target.parent.mkdir(parents=True, exist_ok=True)
            target.touch()
        for name in ('README.md', 'LICENSE', '.gitignore'):
            (self.root / name).write_text('')
        self.git('add', '.')

    def git(self, *arguments):
        return subprocess.run(['git', *arguments], cwd=self.root, check=True, capture_output=True)

    def validate(self):
        return subprocess.run([sys.executable, str(SCRIPT)], cwd=self.root, capture_output=True, text=True)

    def test_clean_checkout_layout_passes_without_local_notes(self):
        result = self.validate()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_index_is_scanned_even_if_worktree_was_sanitized(self):
        fixture = 'ghp_' + 'x' * 36
        (self.root / 'example.txt').write_text(fixture + '\n')
        self.git('add', 'example.txt')
        (self.root / 'example.txt').write_text('sanitized\n')
        result = self.validate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('possible secret', result.stderr)
        self.assertNotIn(fixture, result.stderr)

    def test_ignored_local_notes_are_never_read(self):
        (self.root / '.git/info/exclude').write_text('*.md\n!/README.md\n')
        (self.root / 'memory.md').write_bytes(b'\xff')
        self.assertEqual(self.validate().returncode, 0)

    def test_missing_tracked_layout_and_links_are_rejected(self):
        self.git('rm', '--cached', 'kubernetes/flux/.gitkeep')
        (self.root / 'README.md').write_text('[Missing](docs/missing.txt)\n')
        self.git('add', 'README.md')
        result = self.validate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('kubernetes/flux', result.stderr)
        self.assertIn('missing tracked link', result.stderr)


if __name__ == '__main__':
    unittest.main()
