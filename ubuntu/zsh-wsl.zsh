# WSL-only workaround for the existing highlighter; never load this on servers.
if [[ -n ${WSL_DISTRO_NAME:-} ]] && (( $+functions[_zsh_highlight] )); then
    if [[ ${functions[_zsh_highlight]} != *'_dotfiles_wsl_original_highlight'* ]]; then
        functions[_dotfiles_wsl_original_highlight]=$functions[_zsh_highlight]
        _zsh_highlight() {
            local _highlight_status=$?
            local -a path=("${(@)path:#/mnt/[a-zA-Z]/*}")
            _dotfiles_wsl_original_highlight "$@"
            return $_highlight_status
        }
    fi
fi
