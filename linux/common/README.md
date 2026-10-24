# Shared Linux configuration

`zsh.zsh` contains the common WSL/server interactive setup: history, vi bindings, completion cache, optional prompt and navigation tools, fzf compatibility, guarded aliases and optional plugins.

The WSL-only highlighter workaround remains in `ubuntu/zsh-wsl.zsh`. The cloud profile uses the WSL Vim/Bash/tmux files as shared bases through small entry points. Machine secrets and service aliases belong outside the repository.
