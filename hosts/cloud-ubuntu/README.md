# Cloud Ubuntu

Uses the shared Zsh base and the WSL Bash, Vim and tmux settings. Remote entry points resolve to the server-local `~/.dotfiles` directory. There are no Windows paths, host IPs or credentials in these files.

Server-specific aliases and private settings stay outside Git in `~/.config/dotfiles/host.sh`. Zsh uses a 50ms key timeout over SSH; WSL keeps its existing 10ms timeout. The old fzf distribution package uses its matching shell scripts. Highlighter and autosuggestion plugins are loaded only when available.

The old fzf-tab entry is no longer loaded by default, matching the WSL key setup. Existing plugin directories are preserved. Vim follows the WSL base; old optional Vim plugins remain installed but are not enabled by this profile.

`~/.profile` is preserved for Bash login behavior. `~/.tmux.conf` is newly managed when it did not previously exist. This profile does not modify SSH daemon policy or install system packages.
