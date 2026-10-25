case $- in *i*) ;; *) return ;; esac
_dotfiles_entry="$(readlink -f -- "${BASH_SOURCE[0]}")"
_dotfiles_root="$(dirname "$(dirname "$(dirname "$_dotfiles_entry")")")"
. "$_dotfiles_root/linux/common/bash.bash"
unset _dotfiles_entry _dotfiles_root
