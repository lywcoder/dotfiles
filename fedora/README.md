# Fedora entry points

WSL Fedora and SSH Fedora use these Bash/Zsh/Vim entries. Bash keeps Fedora /etc/bashrc, then sources linux/common/bash.bash.
New installs link ~/.tmux.conf directly to linux/common/tmux.conf; .tmux.conf here is a legacy-compatible loader of the same common file.
Run bash scripts/install-linux.sh --dry-run from the clone, then remove --dry-run to install for the current user.
See ../docs/installation.md.
