#!/usr/bin/env bash
# Standalone Debian entry: download this file, or run it from an existing clone.
set -Eeuo pipefail
. /etc/os-release
[[ ${ID:-} == debian ]] || { printf 'This entry supports Debian GNU/Linux (ID=debian).\n' >&2; exit 1; }
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
if [[ -d $script_dir/../.git && -f $script_dir/bootstrap.sh && -f $script_dir/../debian/.bashrc ]]; then
    exec bash "$script_dir/bootstrap.sh" "$@"
fi
for argument in "$@"; do
    case $argument in
        --dry-run)
            printf 'PREVIEW: download the shared bootstrap, clone into this Linux system (default ~/.dotfiles), install Debian dependencies/plugins and back up/link Bash, Zsh, Vim, tmux.\n'
            printf 'No files, downloads, packages or links changed. Full path checks run in bootstrap before cloning.\n'
            exit 0 ;;
        -h|--help)
            printf 'Usage: download-debian.sh [--profile auto|debian|wsl-debian|ssh-debian] [--dir PATH] [--dry-run] [--skip-dependencies] [--skip-plugins] [--extras]\n'
            exit 0 ;;
    esac
done
command -v curl >/dev/null 2>&1 || { printf 'Install curl and CA certificates first; see docs/debian-linux.md.\n' >&2; exit 1; }
temporary=$(mktemp -d /tmp/dotfiles-debian-bootstrap.XXXXXX)
cleanup() {
    rm -f -- "$temporary/bootstrap.sh"
    rmdir -- "$temporary"
}
trap cleanup EXIT
curl --fail --location --proto '=https' --tlsv1.2 --connect-timeout 15 --max-time 120 --retry 2 \
    https://raw.githubusercontent.com/lywcoder/dotfiles/main/scripts/bootstrap.sh -o "$temporary/bootstrap.sh"
bash "$temporary/bootstrap.sh" "$@"
