# Resolve the real repository even when this entry point is a symlink.
typeset -g DOTFILES_ROOT="${${(%):-%N}:A:h:h}"
source "$DOTFILES_ROOT/linux/common/zsh.zsh"
if [[ -o interactive ]]; then
    source "$DOTFILES_ROOT/ubuntu/zsh-wsl.zsh"
fi
