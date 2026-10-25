# Compatibility loader; the WSL behavior is shared by all Linux distributions.
_dotfiles_wsl_root="${${(%):-%N}:A:h:h}"
source "$_dotfiles_wsl_root/linux/common/wsl.zsh"
unset _dotfiles_wsl_root
