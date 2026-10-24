typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)
export PATH
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

[[ -o interactive ]] || return

bindkey -v
KEYTIMEOUT=1

HISTFILE="$HOME/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS

autoload -Uz compinit
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -s "$_zcompdump" && -z "$_zcompdump"(#qN.mh+24) ]]; then
    compinit -C -d "$_zcompdump"
else
    if compinit -d "$_zcompdump" && [[ -w "$_zcompdump" ]]; then
        touch -- "$_zcompdump"
    fi
fi
unset _zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# New fzf embeds integration; distro versions before 0.48 need matching scripts.
if command -v fzf >/dev/null 2>&1; then
    if _dotfiles_fzf_init="$(command fzf --zsh 2>/dev/null)" && [[ -n $_dotfiles_fzf_init ]]; then
        eval "$_dotfiles_fzf_init"
    else
        for _dotfiles_fzf_script in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/key-bindings.zsh "$HOME/.fzf/shell/key-bindings.zsh"; do
            if [[ -r $_dotfiles_fzf_script ]]; then
                source "$_dotfiles_fzf_script"
                break
            fi
        done
        for _dotfiles_fzf_script in /usr/share/doc/fzf/examples/completion.zsh /usr/share/fzf/completion.zsh "$HOME/.fzf/shell/completion.zsh"; do
            if [[ -r $_dotfiles_fzf_script ]]; then
                source "$_dotfiles_fzf_script"
                break
            fi
        done
    fi
    unset _dotfiles_fzf_init _dotfiles_fzf_script
fi

if command -v eza >/dev/null 2>&1; then
    alias e='eza'
    alias ll='eza -lh --icons --group-directories-first'
    alias la='eza -lha --icons --group-directories-first'
else
    alias ll='ls -lh --color=auto'
    alias la='ls -lha --color=auto'
fi

if command -v lazygit >/dev/null 2>&1; then
    alias lg='lazygit'
fi
if command -v yazi >/dev/null 2>&1; then
    alias y='yazi'
fi

if command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi
alias ..='cd ..'
alias ...='cd ../..'

ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200
for _dotfiles_plugin in "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    if [[ -r $_dotfiles_plugin ]]; then
        source "$_dotfiles_plugin"
        bindkey -M viins '^E' autosuggest-accept
        break
    fi
done
unset _dotfiles_plugin

# Load only one highlighter, after the other key bindings.
for _dotfiles_plugin in "$HOME/.zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    if [[ -r $_dotfiles_plugin ]]; then
        source "$_dotfiles_plugin"
        break
    fi
done
unset _dotfiles_plugin
