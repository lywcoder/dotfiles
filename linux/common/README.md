# Shared configuration

Bash/Zsh/Vim/tmux settings live here. Ubuntu and Fedora retain small entry files; Fedora Bash sources /etc/bashrc first.
The installer links tmux directly to common/tmux.conf. Older distro tmux entries dynamically resolve and load the same common file, including custom clone paths.
Zsh detects SSH latency, supports both modern and older fzf, and uses at most one syntax highlighter.
WSL-only path handling is guarded in linux/common/wsl.zsh; ubuntu/zsh-wsl.zsh is a compatibility loader. No private data or downloaded plugins belong here.
See ../../docs/installation.md for dependencies, private overrides and installation commands.
