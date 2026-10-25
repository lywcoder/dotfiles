# Resolve the repository through the entry symlink; never source this file again.
case $- in *i*) ;; *) return ;; esac
[ ! -r /etc/bashrc ] || . /etc/bashrc
_dotfiles_entry="$(readlink -f -- "${BASH_SOURCE[0]}")"
_dotfiles_root="$(dirname "$(dirname "$_dotfiles_entry")")"
. "$_dotfiles_root/linux/common/bash.bash"
unset _dotfiles_entry _dotfiles_root
