#!/usr/bin/env python3
"""Arch branch tests with an os-release fixture; package operations are always simulated.

Run on a Linux test host with Bash/Zsh/Vim/tmux. Nothing changes /etc or real HOME.
The inherited suite checks the same boundaries, backup/rollback and shared behavior.
"""
import os
from pathlib import Path
import subprocess
import unittest

import test_install_linux as linux_tests


class ArchInstallTests(linux_tests.LinuxInstallTests):
    def setUp(self):
        super().setUp()
        self.distro = 'arch'
        fixture = self.base / 'arch-os-release'
        fixture.write_text('ID=arch\nNAME="Arch Linux"\n')
        for name in ['install-linux.sh', 'bootstrap.sh', 'download-arch.sh']:
            script = self.repo / 'scripts' / name
            text = script.read_text()
            self.assertIn('. /etc/os-release', text)
            script.write_text(text.replace('. /etc/os-release', '. "' + str(fixture) + '"'))

    def test_all_arch_profiles_preview_and_read_only(self):
        for profile in ['arch', 'wsl-arch', 'ssh-arch']:
            result = self.run_install('--profile', profile, '--dry-run')
            self.assertIn('Profile: ' + profile, result.stdout)
            self.assertIn(str(self.repo / 'arch/.bashrc'), result.stdout)
            self.assertIn(str(self.repo / 'linux/common/tmux.conf'), result.stdout)
            self.assertEqual(list(self.home.iterdir()), [])

    def test_arch_startup_files_only_load_common_configuration(self):
        for name in ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']:
            text = (self.repo / 'arch' / name).read_text()
            self.assertIn('linux/common/', text)
            self.assertNotIn('windows/', text)
        bashrc = (self.repo / 'arch/.bashrc').read_text()
        self.assertNotIn('. /etc/bash.bashrc', bashrc)
        self.assertNotIn('. /etc/bashrc', bashrc)

    def test_arch_download_launchers_existing_clone(self):
        # These launchers delegate clone/dependency/link behavior to bootstrap.
        (self.repo / '.git').mkdir()
        for name in ['install-arch.sh', 'install-wsl-arch.sh', 'install-ssh-arch.sh', 'download-arch.sh']:
            result = subprocess.run(['bash', str(self.repo / 'scripts' / name), '--dir', str(self.repo), '--dry-run', '--skip-dependencies', '--skip-plugins'], env=self.env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn('PREVIEW only', result.stdout)
            self.assertEqual(list(self.home.iterdir()), [])

    def test_standalone_download_preview_is_read_only(self):
        standalone = self.base / 'download-arch.sh'
        standalone.write_text((self.repo / 'scripts/download-arch.sh').read_text())
        result = subprocess.run(['bash', str(standalone), '--dry-run'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('No files, downloads, packages or links changed', result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_bootstrap_can_install_initial_git_with_pacman(self):
        bootstrap = self.repo / 'scripts/bootstrap.sh'
        bootstrap.write_text(bootstrap.read_text().replace('if ! command -v git >/dev/null 2>&1; then', 'if true; then'))
        # A tiny cloned installer keeps this test focused on the pre-clone Git step.
        self.installer.write_text('#!/usr/bin/env bash\nprintf "ARCH_BOOTSTRAP_OK\\n"\n')
        for args in [
            ['git', 'init', '-b', 'main', str(self.repo)],
            ['git', '-C', str(self.repo), 'add', '.'],
            ['git', '-C', str(self.repo), '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'fixture'],
        ]:
            subprocess.run(args, check=True, capture_output=True)
        bindir = self.base / 'initial-git-package-tools'
        bindir.mkdir()
        log = self.base / 'pacman-log'
        pacman = bindir / 'pacman'
        pacman.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$ARCH_TEST_LOG"\n')
        pacman.chmod(0o755)
        sudo = bindir / 'sudo'
        sudo.write_text('#!/bin/sh\n[ "$1" != -- ] || shift\nexec "$@"\n')
        sudo.chmod(0o755)
        env = dict(self.env, PATH=str(bindir) + ':' + os.environ['PATH'], ARCH_TEST_LOG=str(log))
        destination = self.home / '.dotfiles'
        result = subprocess.run(['bash', str(bootstrap), '--repo', str(self.repo), '--dir', str(destination)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('ARCH_BOOTSTRAP_OK', result.stdout)
        self.assertEqual(log.read_text().strip(), '-S --needed --noconfirm git ca-certificates')

    def test_skip_dependencies_does_not_install_initial_git(self):
        bootstrap = self.repo / 'scripts/bootstrap.sh'
        bootstrap.write_text(bootstrap.read_text().replace('if ! command -v git >/dev/null 2>&1; then', 'if true; then'))
        destination = self.home / '.dotfiles'
        result = subprocess.run(['bash', str(bootstrap), '--dir', str(destination), '--skip-dependencies'], env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Git is required to clone', result.stderr)
        self.assertFalse(destination.exists())

    def test_arch_package_failure_preserves_original_entries(self):
        for name in ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']:
            (self.home / name).write_text('original ' + name)
        bindir = self.base / 'failed-package-manager'
        bindir.mkdir()
        pacman = bindir / 'pacman'
        pacman.write_text('#!/bin/sh\nexit 73\n')
        pacman.chmod(0o755)
        sudo = bindir / 'sudo'
        sudo.write_text('#!/bin/sh\n[ "$1" != -- ] || shift\nexec "$@"\n')
        sudo.chmod(0o755)
        env = dict(self.env, PATH=str(bindir) + ':' + os.environ['PATH'])
        result = subprocess.run(['bash', str(self.installer), '--skip-plugins'], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 73, result.stdout + result.stderr)
        for name in ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']:
            self.assertFalse((self.home / name).is_symlink())
            self.assertEqual((self.home / name).read_text(), 'original ' + name)
        self.assertFalse((self.home / '.local').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
