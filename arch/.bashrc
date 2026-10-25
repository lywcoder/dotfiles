# Arch Bash reads /etc/bash.bashrc itself; do not load it twice here.
# Resolve the repository through the entry symlink; never source this file again.
case $- in *i*) ;; *) return ;; esac
_dotfiles_entry="$(readlink -f -- "${BASH_SOURCE[0]}")"
_dotfiles_root="$(dirname "$(dirname "$_dotfiles_entry")")"
. "$_dotfiles_root/linux/common/bash.bash"
unset _dotfiles_entry _dotfiles_root
