# Resolve the actual repository, independent of its clone location.
typeset -g DOTFILES_ROOT="${${(%):-%N}:A:h:h}"
source "$DOTFILES_ROOT/linux/common/zsh.zsh"
if [[ -o interactive ]]; then
    source "$DOTFILES_ROOT/linux/common/wsl.zsh"
fi
