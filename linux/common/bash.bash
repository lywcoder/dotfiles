# Shared interactive Bash behavior. Distro-specific system loading is in each entry.
case $- in *i*) ;; *) return ;; esac
export EDITOR=vim VISUAL=vim
for _dotfiles_bin in "$HOME/.cargo/bin" "$HOME/.local/bin"; do
    case ":$PATH:" in *":$_dotfiles_bin:"*) ;; *) PATH="$_dotfiles_bin:$PATH" ;; esac
done
unset _dotfiles_bin
export PATH
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
HISTCONTROL=ignoreboth
HISTSIZE=20000
HISTFILESIZE=20000
shopt -s histappend checkwinsize
PS1='\u@\h:\w\$ '
if command -v dircolors >/dev/null 2>&1; then
    if [[ -r "$HOME/.dircolors" ]]; then eval "$(dircolors -b "$HOME/.dircolors")";
    else eval "$(dircolors -b)"; fi
fi
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
if command -v eza >/dev/null 2>&1; then
    alias e='eza'
    alias ll='eza -lh --icons --group-directories-first'
    alias la='eza -lha --icons --group-directories-first'
fi
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'
command -v yazi >/dev/null 2>&1 && alias y='yazi'
if ! shopt -oq posix && ! declare -F _init_completion >/dev/null; then
    for _dotfiles_file in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
        if [[ -r $_dotfiles_file ]]; then . "$_dotfiles_file"; break; fi
    done
fi
if command -v fzf >/dev/null 2>&1; then
    if _dotfiles_fzf_init="$(command fzf --bash 2>/dev/null)" && [[ -n $_dotfiles_fzf_init ]]; then
        eval "$_dotfiles_fzf_init"
    else
        for _dotfiles_file in /usr/share/doc/fzf/examples/key-bindings.bash /usr/share/fzf/shell/key-bindings.bash /usr/share/fzf/key-bindings.bash; do
            if [[ -r $_dotfiles_file ]]; then . "$_dotfiles_file"; break; fi
        done
        for _dotfiles_file in /usr/share/doc/fzf/examples/completion.bash /usr/share/fzf/shell/completion.bash /usr/share/fzf/completion.bash; do
            if [[ -r $_dotfiles_file ]]; then . "$_dotfiles_file"; break; fi
        done
    fi
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
[[ ! -r "$HOME/.bash_aliases" ]] || . "$HOME/.bash_aliases"
[[ ! -r "$HOME/.config/dotfiles/host.sh" ]] || . "$HOME/.config/dotfiles/host.sh"
[[ ! -r "$HOME/.config/dotfiles/bash.local.sh" ]] || . "$HOME/.config/dotfiles/bash.local.sh"
unset _dotfiles_file _dotfiles_fzf_init
