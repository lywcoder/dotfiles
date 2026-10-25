typeset -g DOTFILES_ROOT="${${(%):-%N}:A:h:h:h}"
source "$DOTFILES_ROOT/linux/common/zsh.zsh"
if [[ -o interactive ]]; then
    KEYTIMEOUT=5
fi
