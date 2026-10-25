#!/usr/bin/env bash
# Invoke with bash. Defaults apply to the current user, never to all users.
set -Eeuo pipefail
umask 077
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
PROFILE=auto DRY_RUN=0 SKIP_DEPS=0 SKIP_PLUGINS=0 EXTRAS=0
usage() {
    cat <<'EOF'
Usage: bash scripts/install-linux.sh [--profile auto|arch|wsl-ubuntu|wsl-fedora|wsl-arch|ssh-ubuntu|ssh-fedora|ssh-arch]
       [--dry-run] [--skip-dependencies] [--skip-plugins] [--extras]
Default: install dependencies/plugins and create four backed-up config symlinks.
Run as the intended account, not "sudo bash ...". root is supported for root's own files.
EOF
}
while (($#)); do
    case $1 in
        --profile) [[ $# -ge 2 ]] || { usage; exit 2; }; PROFILE=$2; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --skip-dependencies) SKIP_DEPS=1; shift ;;
        --skip-plugins) SKIP_PLUGINS=1; shift ;;
        --extras) EXTRAS=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done
say() { printf '%s\n' "$*"; }
die() { say "ERROR: $*" >&2; exit 1; }
[[ -z ${SUDO_USER:-} || ${SUDO_USER} == root ]] || die 'Run without sudo; the installer elevates only package operations.'
[[ -r /etc/os-release ]] || die '/etc/os-release is missing.'
# shellcheck source=/dev/null
. /etc/os-release
case ${ID:-} in ubuntu|fedora|arch) DISTRO=$ID ;; *) die "Supported distributions: Ubuntu, Fedora, Arch Linux (found ${ID:-unknown})." ;; esac
if [[ $PROFILE == auto ]]; then
    if [[ -n ${WSL_DISTRO_NAME:-} ]] || grep -qi microsoft /proc/sys/kernel/osrelease; then
        PROFILE=wsl-$DISTRO
    elif [[ $DISTRO == arch && -z ${SSH_CONNECTION:-} ]]; then
        PROFILE=arch
    else
        PROFILE=ssh-$DISTRO
    fi
fi
case $PROFILE in arch|wsl-ubuntu|wsl-fedora|wsl-arch|ssh-ubuntu|ssh-fedora|ssh-arch) ;; *) die "Invalid profile: $PROFILE" ;; esac
[[ ${PROFILE##*-} == "$DISTRO" ]] || die "Profile $PROFILE does not match $DISTRO."
[[ -z ${ZDOTDIR:-} || ${ZDOTDIR} == "$HOME" ]] || die 'Custom ZDOTDIR detected; configure its entry manually before installation.'
# BEGIN filesystem boundary checks (also embedded in bootstrap/install-linux).
require_linux_path() {
    local requested=$1 physical probe fs
    command -v realpath >/dev/null 2>&1 && command -v findmnt >/dev/null 2>&1 || {
        printf 'ERROR: realpath and findmnt are required (coreutils/util-linux).\n' >&2; return 1;
    }
    physical=$(realpath -m -- "$requested") || return 1
    probe=$physical
    while [[ ! -e $probe ]]; do probe=$(dirname -- "$probe"); done
    fs=$(findmnt -n -o FSTYPE -T "$probe") || {
        printf 'ERROR: cannot determine filesystem: %s\n' "$physical" >&2; return 1;
    }
    case $fs in
        ext2|ext3|ext4|btrfs|xfs|zfs|f2fs|bcachefs|overlay|tmpfs|ramfs) ;;
        *)
            printf 'ERROR: use the local Linux filesystem, not Windows/network or unsupported storage: %s (%s)\n' "$physical" "$fs" >&2
            return 1 ;;
    esac
    printf '%s\n' "$physical"
}
require_repo_source() {
    local physical
    physical=$(require_linux_path "$1") || return 1
    [[ $physical == "$ROOT/"* ]] || {
        printf 'ERROR: configuration source escapes this clone: %s\n' "$physical" >&2; return 1;
    }
}
# END filesystem boundary checks.
ROOT=$(require_linux_path "$ROOT")
HOME_PHYSICAL=$(require_linux_path "$HOME")
for source_dir in "$ROOT/linux/common" "$ROOT/$DISTRO"; do require_repo_source "$source_dir"; done
# Startup helpers, not just the four entry files, must stay in this Linux clone.
for source_file in "$ROOT"/linux/common/* "$ROOT/$DISTRO"/.* "$ROOT/ubuntu/zsh-wsl.zsh"; do
    [[ -f $source_file || -L $source_file ]] || continue
    require_repo_source "$source_file"
done
if ((!SKIP_PLUGINS)); then
    require_linux_path "$HOME/.vim" >/dev/null
    require_linux_path "$HOME/.zsh/plugins" >/dev/null
fi
[[ -n ${HOME:-} && -d $HOME && $HOME != / ]] || die 'HOME must be an existing user home.'
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
SOURCES=("$ROOT/$DISTRO/.bashrc" "$ROOT/$DISTRO/.zshrc" "$ROOT/$DISTRO/.vimrc" "$ROOT/linux/common/tmux.conf")
DESTS=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.tmux.conf")
for i in "${!DESTS[@]}"; do
    require_repo_source "${SOURCES[i]}"
    [[ -f ${SOURCES[i]} ]] || die "Missing source: ${SOURCES[i]}"
    [[ ! -d ${DESTS[i]} || -L ${DESTS[i]} ]] || die "Refusing to replace a real directory: ${DESTS[i]}"
done
say "Profile: $PROFILE | Repository: $ROOT | User home: $HOME"
if ((DRY_RUN)); then
    say "PREVIEW only: no package operations, downloads, backups or links."
    ((SKIP_DEPS)) || say "Dependencies: $DISTRO package manager (sudo if required), Starship user-local fallback; extras=$EXTRAS."
    ((SKIP_PLUGINS)) || say 'Plugins: vim-plug + lightline, surround, auto-pairs, gruvbox; Zsh autosuggestions + fast syntax highlighting.'
    for i in "${!DESTS[@]}"; do say "LINK ${DESTS[i]} -> ${SOURCES[i]} (back up any different entry)"; done
    if [[ $DISTRO == arch ]] && ((!SKIP_DEPS)); then
        say 'Arch: pacman -S --needed; update the system with pacman -Syu yourself before installation. No -Sy or full system upgrade is run here.'
    fi
    say 'Existing theme, login files, default shell and running sessions are preserved.'
    exit 0
fi
as_root() {
    if ((EUID == 0)); then "$@";
    elif command -v sudo >/dev/null 2>&1; then sudo -- "$@";
    else die 'sudo is unavailable; ask the administrator to install dependencies, then use --skip-dependencies.'; fi
}
optional_package() {
    local pkg=$1
    if [[ $DISTRO == ubuntu ]]; then
        if apt-cache show "$pkg" >/dev/null 2>&1; then as_root apt-get install -y "$pkg" || return 1;
        else say "OPTIONAL unavailable in enabled repositories: $pkg"; fi
    elif [[ $DISTRO == arch ]]; then
        if pacman -Si -- "$pkg" >/dev/null 2>&1; then as_root pacman -S --needed --noconfirm -- "$pkg" || return 1;
        else say "OPTIONAL unavailable in enabled repositories: $pkg"; fi
    else
        if dnf -q list "$pkg" >/dev/null 2>&1; then as_root dnf install -y "$pkg" || return 1;
        else say "OPTIONAL unavailable in enabled repositories: $pkg"; fi
    fi
}
if ((!SKIP_DEPS)); then
    if [[ $DISTRO == ubuntu ]]; then
        as_root apt-get update
        as_root apt-get install -y git curl ca-certificates bash bash-completion zsh vim tmux fzf zoxide bat
    elif [[ $DISTRO == arch ]]; then
        # Do not use -Sy (partial upgrades) or silently upgrade the entire system.
        # The user updates Arch first; install against the existing sync databases.
        as_root pacman -S --needed --noconfirm git curl ca-certificates bash bash-completion zsh vim tmux fzf zoxide bat starship eza
    else
        # Fedora cloud images may already supply curl via curl-minimal.
        packages=(git ca-certificates bash bash-completion zsh vim-enhanced tmux fzf zoxide bat)
        command -v curl >/dev/null 2>&1 || packages+=(curl)
        as_root dnf install -y "${packages[@]}"
    fi
    command -v eza >/dev/null 2>&1 || optional_package eza
    if ! command -v starship >/dev/null 2>&1; then
        # Use the official installer without enabling third-party apt/COPR repositories.
        mkdir -p -- "$HOME/.local/bin"
        installer=$(mktemp)
        trap 'rm -f -- "${installer:-}"' EXIT
        curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 15 --max-time 120 --retry 2 https://starship.rs/install.sh -o "$installer"
        sh "$installer" --yes --bin-dir "$HOME/.local/bin"
        rm -f -- "$installer"
        trap - EXIT
    fi
    if ((EXTRAS)); then
        optional_package lazygit
        optional_package yazi
        optional_package fastfetch
    fi
fi
clone_plugin() {
    local url=$1 dest=$2 required=$3 parent temp
    if [[ -e $dest || -L $dest ]]; then
        [[ -d $dest && -f $dest/$required ]] || die "Incomplete plugin directory; review manually: $dest"
        say "KEEP existing plugin: $dest"
        return
    fi
    parent=$(dirname -- "$dest")
    mkdir -p -- "$parent"
    temp=$(mktemp -d "$parent/.dotfiles-download.XXXXXX")
    if ! git -c http.lowSpeedLimit=1 -c http.lowSpeedTime=45 clone --depth 1 -- "$url" "$temp"; then
        say "Download failed; temporary directory retained for inspection: $temp" >&2
        return 1
    fi
    [[ -f $temp/$required ]] || die "Downloaded plugin lacks $required; inspect $temp"
    mv -T -- "$temp" "$dest"
}
if ((!SKIP_PLUGINS)); then
    command -v git >/dev/null 2>&1 || die 'git is needed for plugins.'
    command -v curl >/dev/null 2>&1 || die 'curl is needed for vim-plug.'
    if [[ ! -s $HOME/.vim/autoload/plug.vim ]]; then
        mkdir -p -- "$HOME/.vim/autoload"
        plug_temp=$(mktemp "$HOME/.vim/autoload/.plug.XXXXXX")
        curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 15 --max-time 120 --retry 2 https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o "$plug_temp"
        mv -T -- "$plug_temp" "$HOME/.vim/autoload/plug.vim"
    fi
    clone_plugin https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/plugins/zsh-autosuggestions" zsh-autosuggestions.zsh
    clone_plugin https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$HOME/.zsh/plugins/fast-syntax-highlighting" fast-syntax-highlighting.plugin.zsh
    clone_plugin https://github.com/itchyny/lightline.vim.git "$HOME/.vim/plugged/lightline.vim" autoload/lightline.vim
    clone_plugin https://github.com/tpope/vim-surround.git "$HOME/.vim/plugged/vim-surround" plugin/surround.vim
    clone_plugin https://github.com/jiangmiao/auto-pairs.git "$HOME/.vim/plugged/auto-pairs" plugin/auto-pairs.vim
    clone_plugin https://github.com/morhetz/gruvbox.git "$HOME/.vim/plugged/gruvbox" colors/gruvbox.vim
fi
for tool in bash zsh vim tmux; do command -v "$tool" >/dev/null 2>&1 || die "Required tool missing: $tool"; done
# Validate before touching entry points. Vim/tmux runtime validation is covered by tests.
for config in "$ROOT/$DISTRO/.bashrc" "$ROOT/linux/common/bash.bash"; do bash -n "$config"; done
for config in "$ROOT/$DISTRO/.zshrc" "$ROOT/linux/common/zsh.zsh"; do zsh -n "$config"; done
BACKUP="$HOME/.local/state/dotfiles-backups/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p -- "$BACKUP"
chmod 700 "$BACKUP"
saved=()
rollback() {
    local status=$? j idx
    trap - ERR
    say 'Link installation failed; restoring entries from this run.' >&2
    for ((j=${#saved[@]}-1; j>=0; j--)); do
        idx=${saved[j]}
        if [[ -L ${DESTS[idx]} && $(readlink -- "${DESTS[idx]}") == "${SOURCES[idx]}" ]]; then rm -- "${DESTS[idx]}"; fi
        if [[ ! -e ${DESTS[idx]} && ! -L ${DESTS[idx]} && ( -e $BACKUP/${DESTS[idx]##*/} || -L $BACKUP/${DESTS[idx]##*/} ) ]]; then
            mv -T -- "$BACKUP/${DESTS[idx]##*/}" "${DESTS[idx]}"
        fi
    done
    exit "$status"
}
trap rollback ERR
for i in "${!DESTS[@]}"; do
    src=${SOURCES[i]} dest=${DESTS[i]}
    if [[ -L $dest && $(readlink -f -- "$dest") == "$(readlink -f -- "$src")" ]]; then say "OK $dest"; continue; fi
    saved+=("$i")
    if [[ -e $dest || -L $dest ]]; then mv -T -- "$dest" "$BACKUP/${dest##*/}"; fi
    ln -sT -- "$src" "$dest"
    say "LINK $dest -> $src"
done
trap - ERR
say "Complete. Backups: $BACKUP"
for tool in starship zoxide fzf eza bat batcat lazygit yazi; do
    if command -v "$tool" >/dev/null 2>&1; then say "AVAILABLE $tool"; else say "OPTIONAL MISSING $tool"; fi
done
say 'Start a new terminal; run zsh to try Zsh. The default login shell has not been changed.'
say 'Existing Starship themes and private ~/.config/dotfiles overrides are preserved.'
