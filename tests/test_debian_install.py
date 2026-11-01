#!/usr/bin/env python3
"""Debian integration checks; changes only temporary clones/HOMEs, never packages."""
import os
from pathlib import Path
import shutil
import subprocess
import unittest

import test_install_linux as linux_tests


class DebianInstallTests(linux_tests.LinuxInstallTests):
    def setUp(self):
        super().setUp()
        self.distro = 'debian'
        fixture = self.base / 'debian-os-release'
        fixture.write_text('ID=debian\nNAME="Debian GNU/Linux"\n')
        for name in ['install-linux.sh', 'bootstrap.sh', 'download-debian.sh']:
            script = self.repo / 'scripts' / name
            if script.exists():
                script.write_text(script.read_text().replace('. /etc/os-release', '. "' + str(fixture) + '"'))

    def offline_tools(self, scripts):
        bindir = self.base / 'offline-tools'
        bindir.mkdir(exist_ok=True)
        for name, body in scripts.items():
            script = bindir / name
            script.write_text('#!/bin/sh\n' + body + '\n')
            script.chmod(0o755)
        return dict(self.env, PATH=str(bindir) + ':' + os.environ['PATH'])

    def without_wsl_detection(self, **values):
        env = self.offline_tools({'grep': 'if [ "$*" = "-qi microsoft /proc/sys/kernel/osrelease" ]; then exit 1; fi\nexec /usr/bin/grep "$@"'})
        return dict(env, WSL_DISTRO_NAME='', SSH_CONNECTION='', **values)

    def test_all_debian_profiles_preview_without_changes(self):
        for profile in ['debian', 'wsl-debian', 'ssh-debian']:
            with self.subTest(profile=profile):
                result = self.run_install('--profile', profile, '--dry-run')
                self.assertIn('Profile: ' + profile, result.stdout)
                self.assertIn(str(self.repo / 'debian/.bashrc'), result.stdout)
                self.assertIn(str(self.repo / 'linux/common/tmux.conf'), result.stdout)
                self.assertEqual(list(self.home.iterdir()), [])

    def test_native_autodetection_selects_debian(self):
        result = self.run_install(env=self.without_wsl_detection())
        self.assertIn('Profile: debian |', result.stdout)
        self.assertEqual((self.home / '.bashrc').resolve(), self.repo / 'debian/.bashrc')

    def test_wsl_autodetection_selects_debian(self):
        result = self.run_install('--dry-run', env=dict(self.env, WSL_DISTRO_NAME='Debian'))
        self.assertIn('Profile: wsl-debian |', result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_ssh_autodetection_selects_debian(self):
        env = self.without_wsl_detection()
        env['SSH_CONNECTION'] = 'test-session'
        result = self.run_install('--dry-run', env=env)
        self.assertIn('Profile: ssh-debian |', result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_existing_clone_launchers_preview_without_changes(self):
        (self.repo / '.git').mkdir()
        for name in ['install-debian.sh', 'install-wsl-debian.sh', 'install-ssh-debian.sh', 'download-debian.sh']:
            with self.subTest(launcher=name):
                result = subprocess.run(['bash', str(self.repo / 'scripts' / name), '--dir', str(self.repo), '--dry-run'], env=self.env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('PREVIEW only', result.stdout)
                self.assertEqual(list(self.home.iterdir()), [])

    def test_standalone_download_preview_does_not_access_network(self):
        source = self.repo / 'scripts/download-debian.sh'
        self.assertTrue(source.is_file(), 'Debian download entry is missing')
        standalone = self.base / 'download-debian.sh'
        standalone.write_text(source.read_text())
        env = self.offline_tools({'curl': 'printf "unexpected network access" >&2; exit 73',
                                  'git': 'printf "unexpected clone" >&2; exit 74'})
        result = subprocess.run(['bash', str(standalone), '--dry-run'], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('No files, downloads, packages or links changed', result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_wrong_distro_launchers_refuse_before_clone_or_packages(self):
        (self.base / 'debian-os-release').write_text('ID=ubuntu\n')
        log = self.base / 'unexpected-operations'
        env = self.offline_tools({name: 'printf "%s\\n" "' + name + ' $*" >> "$DEBIAN_TEST_LOG"\nexit 73'
                                  for name in ['git', 'apt-get', 'dnf', 'pacman']})
        env['DEBIAN_TEST_LOG'] = str(log)
        for name in ['install-debian.sh', 'install-wsl-debian.sh', 'install-ssh-debian.sh']:
            with self.subTest(launcher=name):
                result = subprocess.run(['bash', str(self.repo / 'scripts' / name)], env=env, capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('does not match ubuntu', result.stderr)
                self.assertFalse(log.exists(), 'Bootstrap ran Git or a package manager before validating the profile')
                self.assertEqual(list(self.home.iterdir()), [])

    def test_bootstrap_validates_last_profile_before_mutation(self):
        log = self.base / 'unexpected-operations'
        env = self.offline_tools({'git': 'printf "unexpected clone" > "$DEBIAN_TEST_LOG"; exit 73'})
        env['DEBIAN_TEST_LOG'] = str(log)
        result = subprocess.run(['bash', str(self.repo / 'scripts/bootstrap.sh'), '--profile', 'ssh-debian', '--profile', 'ssh-ubuntu'], env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('does not match debian', result.stderr)
        self.assertFalse(log.exists())
        self.assertEqual(list(self.home.iterdir()), [])

    def test_bootstrap_installs_initial_git_with_apt(self):
        # Hide Git from PATH, then let the fake package installer make it available.
        for args in [['git', 'init', '-b', 'main', str(self.repo)],
                     ['git', '-C', str(self.repo), 'add', '.'],
                     ['git', '-C', str(self.repo), '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'fixture']]:
            subprocess.run(args, check=True, capture_output=True)
        self.installer.write_text('#!/usr/bin/env bash\nprintf "DEBIAN_BOOTSTRAP_OK\\n"\n')
        # Commit the tiny installer so the local clone need not execute a real install.
        subprocess.run(['git', '-C', str(self.repo), 'add', '.'], check=True, capture_output=True)
        subprocess.run(['git', '-C', str(self.repo), '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'bootstrap fixture'], check=True, capture_output=True)
        bindir = self.base / 'minimal-bin'
        bindir.mkdir()
        for name in ['bash', 'dirname', 'realpath', 'findmnt', 'mkdir', 'chmod']:
            (bindir / name).symlink_to(shutil.which(name))
        apt = bindir / 'apt-get'
        apt.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$DEBIAN_TEST_LOG"\n'
                       'if [ "$1" = install ]; then\n'
                       ' printf \'#!/bin/sh\\nexec /usr/bin/git "$@"\\n\' > "$DEBIAN_TEST_BIN/git"\n'
                       ' chmod 755 "$DEBIAN_TEST_BIN/git"\nfi\n')
        apt.chmod(0o755)
        sudo = bindir / 'sudo'
        sudo.write_text('#!/bin/sh\n[ "$1" != -- ] || shift\nexec "$@"\n')
        sudo.chmod(0o755)
        log = self.base / 'apt-log'
        env = dict(self.env, PATH=str(bindir), DEBIAN_TEST_LOG=str(log), DEBIAN_TEST_BIN=str(bindir))
        destination = self.home / '.dotfiles'
        result = subprocess.run(['/bin/bash', str(self.repo / 'scripts/bootstrap.sh'), '--repo', str(self.repo), '--dir', str(destination)], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('DEBIAN_BOOTSTRAP_OK', result.stdout)
        self.assertEqual(log.read_text().splitlines(), ['update', 'install -y git ca-certificates'])

    def test_skip_dependencies_with_missing_git_preserves_home(self):
        bindir = self.base / 'no-git-bin'
        bindir.mkdir()
        for name in ['dirname', 'realpath', 'findmnt']:
            (bindir / name).symlink_to(shutil.which(name))
        env = dict(self.env, PATH=str(bindir))
        result = subprocess.run(['/bin/bash', str(self.repo / 'scripts/bootstrap.sh'), '--skip-dependencies'], env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Git is required to clone', result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_package_failure_preserves_original_entries(self):
        names = ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']
        for name in names:
            (self.home / name).write_text('original ' + name)
        env = self.offline_tools({'apt-get': 'exit 73', 'sudo': '[ "$1" != -- ] || shift\nexec "$@"'})
        result = subprocess.run(['bash', str(self.installer), '--skip-plugins'], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 73, result.stdout + result.stderr)
        for name in names:
            self.assertFalse((self.home / name).is_symlink())
            self.assertEqual((self.home / name).read_text(), 'original ' + name)
        self.assertFalse((self.home / '.local').exists())

    def test_missing_optional_packages_are_reported_not_installed(self):
        log = self.base / 'apt-log'
        env = self.offline_tools({'apt-get': 'printf "%s\\n" "$*" >> "$DEBIAN_TEST_LOG"',
                                  'apt-cache': 'exit 1', 'starship': ':',
                                  'sudo': '[ "$1" != -- ] || shift\nexec "$@"'})
        env['DEBIAN_TEST_LOG'] = str(log)
        result = subprocess.run(['bash', str(self.installer), '--skip-plugins', '--extras'], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('OPTIONAL unavailable in enabled repositories: lazygit', result.stdout)
        self.assertIn('install -y git curl ca-certificates bash bash-completion zsh vim tmux fzf zoxide bat', log.read_text())
        self.assertNotIn('lazygit', log.read_text())

    def test_plugin_download_failure_preserves_original_entries(self):
        names = ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']
        for name in names:
            (self.home / name).write_text('original ' + name)
        env = self.offline_tools({'curl': 'exit 73'})
        result = subprocess.run(['bash', str(self.installer), '--skip-dependencies'], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 73, result.stdout + result.stderr)
        for name in names:
            self.assertFalse((self.home / name).is_symlink())
            self.assertEqual((self.home / name).read_text(), 'original ' + name)


if __name__ == '__main__':
    unittest.main(verbosity=2)
