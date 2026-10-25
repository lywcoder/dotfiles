# Arch Linux configuration

Native Arch, WSL Arch and SSH Arch use these small entry files. Bash, Zsh, tmux and Vim all load the existing linux/common configuration; there is no separate copy of their main settings.
Arch Bash reads /etc/bash.bashrc itself. This user entry avoids loading that system file twice. Existing login files and the default shell are preserved.
The installer links ~/.tmux.conf directly to linux/common/tmux.conf; .tmux.conf here supports manual/legacy links and resolves the current clone dynamically.

From an existing Linux clone: bash scripts/install-linux.sh --dry-run, then remove --dry-run. The installer detects Arch automatically.
Scenario launchers: scripts/install-arch.sh, scripts/install-wsl-arch.sh, scripts/install-ssh-arch.sh.
Standalone download entry: scripts/download-arch.sh.

All clones and config sources must reside on the current system's Linux filesystem. See ../docs/arch-linux.md for commands, packages and validation limits.
