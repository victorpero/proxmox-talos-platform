#!/usr/bin/env python3
"""Validate the Git index without reading ignored local files or printing secrets."""

import ipaddress
import json
from pathlib import PurePosixPath
import re
import subprocess
import sys


DOCUMENTATION_NETWORKS = tuple(
    ipaddress.ip_network(value)
    for value in ('192.0.2.0/24', '198.51.100.0/24', '203.0.113.0/24', '2001:db8::/32')
)
REQUIRED_DIRECTORIES = (
    '.github/workflows', 'terraform/modules/proxmox-vm',
    'terraform/environments/dev', 'terraform/environments/prod',
    'ansible/roles/proxmox', 'ansible/playbooks', 'kubernetes/flux',
    'kubernetes/traefik', 'kubernetes/metallb', 'kubernetes/monitoring',
    'kubernetes/applications', 'docs', 'issues', 'scripts',
)
IPV4 = re.compile(r'(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?:/\d{1,2})?(?![\w./])')
IPV6 = re.compile(r'(?<![\w:])(?:[\da-fA-F]*:){2,}[\da-fA-F:.]*(?:/\d{1,3})?(?![\w:])')
MAC = re.compile(r'(?i)(?<![\w:])(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}(?![\w:])')
SENSITIVE_NAME = re.compile(
    r'(?i)(^|/)(?:kubeconfig[^/]*|talosconfig[^/]*|secrets\.ya?ml|'
    r'\.env(?:\..*)?|\.vault_password|backend_override\.tf)$|'
    r'\.backend\.hcl$|'
    r'\.(?:pem|key|p12|pfx|agekey|kubeconfig|talosconfig|tfplan)$|'
    r'\.tfstate(?:\..*)?$|\.sops\.ya?ml\.dec$'
)
SECRET_PATTERNS = (
    re.compile(r'-----BEGIN (?:[A-Z0-9]+ )?PRIVATE KEY-----'),
    re.compile(r'\bgh[pousr]_[A-Za-z0-9]{36,}\b'),
    re.compile(r'\bgithub_pat_[A-Za-z0-9_]{50,}\b'),
    re.compile(r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
    re.compile(r'\bAGE-SECRET-KEY-[A-Z0-9]+\b'),
    re.compile(r'https?://[^\s/@]+:[^\s/@]+@'),
    re.compile(
        r'(?im)^\s*[\w.-]*(?:token|password|secret|client[_-]?key[_-]?data)'
        r'\s*[:=]\s*[\'\"]?[^\s\'\"#]+'
    ),
)


def file_errors(name, data):
    """Return diagnostics containing only filenames, line numbers, and rule names."""
    errors = []
    path = PurePosixPath(name)
    if path.suffix.lower() == '.md' and name != 'README.md':
        errors.append(f'{name}: only the root README.md may be tracked')
    if SENSITIVE_NAME.search(name) or '.terraform' in path.parts:
        errors.append(f'{name}: generated or sensitive artifact must remain untracked')
    if name.endswith(('.tfvars', '.tfvars.json')) and not name.endswith(
        ('.example.tfvars', '.example.tfvars.json')
    ):
        errors.append(f'{name}: variable files must use the .example.tfvars convention')
    try:
        text = data.decode('utf-8')
    except UnicodeDecodeError:
        return errors + [f'{name}: binary files require an explicit validation policy']
    if '\x00' in text:
        errors.append(f'{name}: binary files require an explicit validation policy')
    if text and not text.endswith('\n'):
        errors.append(f'{name}: missing final newline')
    for number, line in enumerate(text.splitlines(keepends=True), 1):
        location = f'{name}:{number}'
        if '\r' in line or line.rstrip('\n').endswith((' ', '\t')):
            errors.append(f'{location}: use LF endings without trailing whitespace')
        if MAC.search(line):
            errors.append(f'{location}: omit hardware MAC addresses from examples')
        for pattern in (IPV4, IPV6):
            for match in pattern.finditer(line):
                try:
                    candidate = ipaddress.ip_network(match.group(), strict=False)
                except ValueError:
                    continue
                if not any(
                    candidate.version == allowed.version and candidate.subnet_of(allowed)
                    for allowed in DOCUMENTATION_NETWORKS
                ):
                    errors.append(f'{location}: address must use a documentation range')
        if any(pattern.search(line) for pattern in SECRET_PATTERNS):
            errors.append(f'{location}: possible secret or embedded credential')
    if name.endswith('.json'):
        try:
            json.loads(text)
        except (ValueError, RecursionError):
            errors.append(f'{name}: invalid JSON')
    return errors


def validate_index():
    entries = subprocess.check_output(['git', 'ls-files', '--stage', '-z']).split(b'\0')
    files = {}
    errors = []
    for entry in filter(None, entries):
        metadata, raw_name = entry.split(b'\t', 1)
        mode, object_id, stage = metadata.decode().split()
        name = raw_name.decode('utf-8')
        if stage != '0' or mode not in ('100644', '100755'):
            errors.append(f'{name}: resolve conflicts and use regular tracked files')
            continue
        data = subprocess.check_output(['git', 'cat-file', 'blob', object_id])
        files[name] = data
        errors.extend(file_errors(name, data))
    for name in ('README.md', 'LICENSE', '.gitignore'):
        if name not in files:
            errors.append(f'{name}: required repository file is missing')
    for directory in REQUIRED_DIRECTORIES:
        if not any(name.startswith(directory + '/') for name in files):
            errors.append(f'{directory}: directory must survive a clean checkout')
    readme = files.get('README.md', b'').decode('utf-8', errors='replace')
    for target in re.findall(r'\]\(([^\s)]+)\)', readme):
        if '://' in target or target.startswith(('#', 'mailto:')):
            continue
        target = target.split('#', 1)[0].removeprefix('./').rstrip('/')
        if target not in files and not any(name.startswith(target + '/') for name in files):
            errors.append(f'README.md: missing tracked link target: {target}')
    return errors, len(files)


def main():
    errors, count = validate_index()
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print(f'Repository boundary, formatting, JSON, layout, and links passed ({count} staged files).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
