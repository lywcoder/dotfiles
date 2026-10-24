# Keep non-interactive SSH commands silent.
case $- in *i*) ;; *) return ;; esac
_dotfiles_entry="$(readlink -f -- "${BASH_SOURCE[0]}")"
_dotfiles_root="$(dirname "$(dirname "$(dirname "$_dotfiles_entry")")")"
. "$_dotfiles_root/ubuntu/.bashrc"
unset _dotfiles_entry _dotfiles_root
if [ -r "$HOME/.config/dotfiles/host.sh" ]; then
    . "$HOME/.config/dotfiles/host.sh"
fi
