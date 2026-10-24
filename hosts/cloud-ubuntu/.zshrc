typeset -g DOTFILES_ROOT="${${(%):-%N}:A:h:h:h}"
source "$DOTFILES_ROOT/linux/common/zsh.zsh"
if [[ -o interactive ]]; then
    # Zsh units are hundredths of a second; allow a little more time over SSH.
    KEYTIMEOUT=5
    export EDITOR=vim
    export VISUAL=vim
    if [[ -r "$HOME/.config/dotfiles/host.sh" ]]; then
        source "$HOME/.config/dotfiles/host.sh"
    fi
fi
