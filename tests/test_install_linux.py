#!/usr/bin/env python3
"""Offline integration checks. Only temporary homes/clones are changed; no packages/network."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]
DISTRO = dict(line.split('=', 1) for line in Path('/etc/os-release').read_text().splitlines() if '=' in line)['ID'].strip('"')


def windows_mount(path):
    result = subprocess.run(['findmnt', '-n', '-o', 'FSTYPE', '-T', str(path)], capture_output=True, text=True)
    return result.stdout.strip() in {'9p', 'drvfs', 'ntfs', 'ntfs3', 'fuseblk', 'cifs', 'smb3'}


class LinuxInstallTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='dotfiles-integration-')
        self.base = Path(self.tmp.name)
        self.repo = self.base / 'clone with spaces'
        shutil.copytree(SOURCE, self.repo, ignore=shutil.ignore_patterns('.git', '__pycache__'))
        self.home = self.base / 'home'
        self.home.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), ZDOTDIR=str(self.home), SUDO_USER='', STARSHIP_CONFIG=str(self.home / 'theme.toml'))
        self.installer = self.repo / 'scripts/install-linux.sh'

    def tearDown(self):
        self.tmp.cleanup()

    def run_install(self, *options, ok=True, env=None):
        result = subprocess.run(['bash', str(self.installer), '--skip-dependencies', '--skip-plugins', *options], env=env or self.env, text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_preview_is_read_only(self):
        self.run_install('--dry-run')
        self.assertEqual(list(self.home.iterdir()), [])

    def test_links_backup_repeat_and_runtime(self):
        names = ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']
        for name in names:
            (self.home / name).write_text('old ' + name)
        result = self.run_install('--profile', 'wsl-' + DISTRO)
        for name in names:
            self.assertTrue((self.home / name).is_symlink())
        backups = self.home / '.local/state/dotfiles-backups'
        for name in names:
            matches = list(backups.glob('*/' + name))
            self.assertEqual(len(matches), 1)
            self.assertEqual(matches[0].read_text(), 'old ' + name)
            self.assertEqual(matches[0].parent.stat().st_mode & 0o777, 0o700)
        self.run_install('--profile', 'ssh-' + DISTRO)
        self.assertEqual(len(list(backups.glob('*/.bashrc'))), 1)
        result = subprocess.run(['bash', '--noprofile', '--rcfile', str(self.home / '.bashrc'), '-ic', 'printf "BASH_OK:%s" "$HISTSIZE"'], env=self.env, capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('BASH_OK:20000', result.stdout)
        env = dict(self.env, SSH_CONNECTION='test')
        result = subprocess.run(['zsh', '-i', '-c', 'print -r -- ZSH_OK:$KEYTIMEOUT:$EDITOR:$DOTFILES_ROOT'], env=env, capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('ZSH_OK:5:vim:' + str(self.repo), result.stdout)
        vim_output = self.base / 'vim-result'
        expr = "call writefile([string(&number), string(&relativenumber), string(&laststatus)], '" + str(vim_output) + "')"
        result = subprocess.run(['vim', '-N', '-u', str(self.home / '.vimrc'), '-i', 'NONE', '-n', '-es', '-c', expr, '-c', 'qa!'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(vim_output.read_text().splitlines(), ['1', '1', '2'])
        socket = str(self.base / 'tmux.sock')
        try:
            result = subprocess.run(['tmux', '-S', socket, '-f', str(self.home / '.tmux.conf'), 'new-session', '-d', '-s', 'test', 'sleep 30'], env=self.env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            result = subprocess.run(['tmux', '-S', socket, 'show-option', '-gv', 'history-limit'], env=self.env, capture_output=True, text=True)
            self.assertEqual(result.stdout.strip(), '20000')
        finally:
            subprocess.run(['tmux', '-S', socket, 'kill-server'], env=self.env, capture_output=True)

    def test_dangling_link_backed_up(self):
        old = self.home / '.bashrc'
        old.symlink_to('/does-not-exist/dotfiles/.bashrc')
        self.run_install()
        matches = list((self.home / '.local/state/dotfiles-backups').glob('*/.bashrc'))
        self.assertEqual(len(matches), 1)
        self.assertEqual(os.readlink(matches[0]), '/does-not-exist/dotfiles/.bashrc')

    def test_refuse_real_directory_before_modification(self):
        (self.home / '.vimrc').mkdir()
        self.run_install(ok=False)
        self.assertFalse((self.home / '.bashrc').exists())
        self.assertFalse((self.home / '.local').exists())

    def test_wrong_distro_refused(self):
        other = 'fedora' if DISTRO == 'ubuntu' else 'ubuntu'
        self.run_install('--profile', 'ssh-' + other, ok=False)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_link_failure_rolls_back(self):
        for name in ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']:
            (self.home / name).write_text('old ' + name)
        bin_dir = self.base / 'bin'
        bin_dir.mkdir()
        wrapper = bin_dir / 'ln'
        wrapper.write_text('#!/usr/bin/env bash\nif [[ ${@: -1} == */.vimrc ]]; then exit 73; fi\nexec /usr/bin/ln "$@"\n')
        wrapper.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + ':' + os.environ['PATH'])
        self.run_install(ok=False, env=env)
        for name in ['.bashrc', '.zshrc', '.vimrc', '.tmux.conf']:
            self.assertFalse((self.home / name).is_symlink())
            self.assertEqual((self.home / name).read_text(), 'old ' + name)

    def test_bootstrap_preview_does_not_clone(self):
        dest = self.home / '.dotfiles'
        result = subprocess.run(['bash', str(self.repo / 'scripts/bootstrap.sh'), '--dir', str(dest), '--dry-run'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(dest.exists())

    def test_bootstrap_local_clone_and_existing_edits(self):
        for args in [
            ['git', 'init', '-b', 'main', str(self.repo)],
            ['git', '-C', str(self.repo), 'add', '.'],
            ['git', '-C', str(self.repo), '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'fixture'],
        ]:
            subprocess.run(args, check=True, capture_output=True)
        dest = self.home / '.dotfiles'
        args = ['bash', str(self.repo / 'scripts/bootstrap.sh'), '--repo', str(self.repo), '--dir', str(dest), '--skip-dependencies', '--skip-plugins']
        result = subprocess.run(args, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.home / '.bashrc').resolve(), dest / DISTRO / '.bashrc')
        marker = dest / 'uncommitted-user-note'
        marker.write_text('keep me')
        result = subprocess.run(args, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(marker.read_text(), 'keep me')

    @unittest.skipUnless(windows_mount('/mnt/c'), 'No Windows C: mount')
    def test_windows_mount_clone_refused(self):
        result = subprocess.run(['bash', str(self.repo / 'scripts/bootstrap.sh'), '--dir', '/mnt/c/dotfiles-must-not-be-created', '--dry-run'], env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('local Linux filesystem', result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    @unittest.skipUnless(windows_mount(SOURCE), 'Source fixture is not on Windows storage')
    def test_symlink_to_windows_clone_refused(self):
        dest = self.home / '.dotfiles'
        dest.symlink_to(SOURCE, target_is_directory=True)
        result = subprocess.run(['bash', str(self.repo / 'scripts/bootstrap.sh'), '--dir', str(dest), '--dry-run'], env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('local Linux filesystem', result.stderr)
        self.assertEqual(list(self.home.iterdir()), [dest])

    @unittest.skipUnless(windows_mount(SOURCE), 'Source fixture is not on Windows storage')
    def test_windows_configuration_source_refused(self):
        config = self.repo / 'linux/common/zsh.zsh'
        config.unlink()
        config.symlink_to(SOURCE / 'linux/common/zsh.zsh')
        result = self.run_install(ok=False)
        self.assertIn('local Linux filesystem', result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_configuration_cannot_escape_clone(self):
        outside = self.base / 'external-vim.vim'
        outside.write_text('set number')
        config = self.repo / 'linux/common/vim.vim'
        config.unlink()
        config.symlink_to(outside)
        result = self.run_install(ok=False)
        self.assertIn('escapes this clone', result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_custom_windows_mount_location_refused(self):
        bin_dir = self.base / 'mount-probe'
        bin_dir.mkdir()
        wrapper = bin_dir / 'findmnt'
        wrapper.write_text('#!/bin/sh\nprintf "9p\\n"\n')
        wrapper.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + ':' + os.environ['PATH'])
        result = self.run_install(ok=False, env=env)
        self.assertIn('local Linux filesystem', result.stderr)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_legacy_tmux_entries_share_common(self):
        common = self.repo / 'linux/common/tmux.conf'
        with common.open('a') as stream:
            stream.write('\nset -g history-limit 54321\n')
        for distro in ['ubuntu', 'fedora']:
            with self.subTest(distro=distro):
                entry = self.home / '.tmux.conf'
                if entry.is_symlink():
                    entry.unlink()
                entry.symlink_to(self.repo / distro / '.tmux.conf')
                socket = str(self.base / (distro + '.sock'))
                try:
                    result = subprocess.run(['tmux', '-S', socket, '-f', str(entry), 'new-session', '-d', '-s', 'compat', 'sleep 20'], env=self.env, capture_output=True, text=True, timeout=10)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    result = subprocess.run(['tmux', '-S', socket, 'show-option', '-gv', 'history-limit'], env=self.env, capture_output=True, text=True, timeout=10)
                    self.assertEqual(result.stdout.strip(), '54321', result.stderr)
                finally:
                    subprocess.run(['tmux', '-S', socket, 'kill-server'], env=self.env, capture_output=True)

    def test_dependency_commands_with_offline_stubs(self):
        bin_dir = self.base / 'fake-package-tools'
        bin_dir.mkdir()
        log = self.base / 'package-log'
        for command in ['apt-get', 'dnf', 'starship', 'eza', 'lazygit', 'yazi', 'fastfetch']:
            wrapper = bin_dir / command
            wrapper.write_text('#!/bin/sh\nprintf "%s\\n" "' + command + ' $*" >> "$DOTFILES_TEST_LOG"\n')
            wrapper.chmod(0o755)
        sudo = bin_dir / 'sudo'
        sudo.write_text('#!/bin/sh\n[ "$1" != -- ] || shift\nexec "$@"\n')
        sudo.chmod(0o755)
        env = dict(self.env, PATH=str(bin_dir) + ':' + os.environ['PATH'], DOTFILES_TEST_LOG=str(log))
        result = subprocess.run(['bash', str(self.installer), '--skip-plugins', '--extras'], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        text = log.read_text()
        self.assertIn('vim-enhanced' if DISTRO == 'fedora' else 'vim', text)
        self.assertIn('zsh', text)
        self.assertIn('tmux', text)
        self.assertNotIn('upgrade', text)


if __name__ == '__main__':
    unittest.main(verbosity=2)
