"""Real psmux smoke test in a private home and unique -L namespace."""
from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile
import time
import uuid

def main():
    if os.name != 'nt' or not shutil.which('psmux'):
        print('SKIP: installed Windows psmux is required.')
        return
    repo = Path(__file__).resolve().parents[1]
    psmux = shutil.which('psmux')
    pwsh = shutil.which('pwsh')
    namespace = 'dotfiles-test-' + uuid.uuid4().hex[:12]
    temporary = tempfile.TemporaryDirectory(prefix='dotfiles-psmux-')
    home = Path(temporary.name)
    env = dict(os.environ, HOME=str(home), USERPROFILE=str(home))
    env.pop('TMUX', None)
    env.pop('TMUX_PANE', None)
    env.pop('PSMUX_CONFIG_FILE', None)
    flags = getattr(subprocess, 'CREATE_NO_WINDOW', 0)
    def command(*args, check=True):
        result = subprocess.run([psmux, '-L', namespace, *args], env=env, cwd=home, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=25, creationflags=flags)
        if check and result.returncode:
            raise RuntimeError('psmux ' + ' '.join(args) + '\n' + result.stdout + result.stderr)
        return result

    started = False
    try:
        install = subprocess.run([pwsh, '-NoLogo', '-NoProfile', '-File', str(repo / 'scripts/install-psmux.ps1'), '-HomeDirectory', str(home), '-Mode', 'Loader'], capture_output=True, text=True, env=env, creationflags=flags, timeout=20)
        assert install.returncode == 0, install.stdout + install.stderr
        entry = home / '.psmux.conf'
        assert 'source-file' in entry.read_text(encoding='utf-8')
        # Exercise normal ~/.psmux.conf discovery, then explicit source-file reload below.
        command('new-session', '-d', '-s', 'unit', '--', 'cmd.exe', '/D', '/Q', '/K')
        started = True
        output = command('show-options', '-g').stdout
        window_output = command('show-window-options', '-g').stdout
        combined = output + window_output
        for option, value in [('history-limit', '20000'), ('base-index', '1'), ('pane-base-index', '1'), ('escape-time', '10'), ('renumber-windows', 'on'), ('mode-keys', 'vi'), ('status-position', 'bottom'), ('default-shell', 'pwsh')]:
            assert re.search(r'^' + re.escape(option) + r'\s+["\']?' + re.escape(value) + r'["\']?\s*$', combined, re.M), (option, combined)
        keys = command('list-keys').stdout
        for expected in ['begin-selection', 'copy-selection-and-cancel', 'pane_current_path', '.psmux.conf', 'select-pane -L', 'select-pane -D', 'select-pane -U', 'select-pane -R']:
            assert expected in keys, (expected, keys)
        command('source-file', str(entry))
        before = command('display-message', '-p', '#{pane_current_path}').stdout.strip()
        command('split-window', '-h', '-c', '#{pane_current_path}', '--', 'cmd.exe', '/D', '/Q', '/K')
        after = command('display-message', '-p', '#{pane_current_path}').stdout.strip()
        assert before and before.casefold() == after.casefold(), (before, after)
        panes = command('list-panes').stdout
        assert len(panes.strip().splitlines()) == 2, panes
        print('PASS: installed psmux loaded the repository config via source-file; settings, vi bindings, reload and split directory inheritance verified.', flush=True)
    finally:
        if started:
            command('kill-server', check=False)
        time.sleep(0.3)
        # The temporary home is uniquely owned by this test. No user psmux directory is removed.
        resolved = home.resolve()
        expected_parent = Path(tempfile.gettempdir()).resolve()
        assert resolved.parent == expected_parent and resolved.name.startswith('dotfiles-psmux-')
        temporary.cleanup()

if __name__ == '__main__':
    main()
