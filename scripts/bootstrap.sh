#!/usr/bin/env bash
set -Eeuo pipefail
REPO=https://github.com/lywcoder/dotfiles.git
BRANCH=main
DEST="$HOME/.dotfiles"
DRY_RUN=0
ARGS=()
while (($#)); do
    case $1 in
        --repo|--branch|--dir) [[ $# -ge 2 ]] || { printf 'Missing value: %s\n' "$1" >&2; exit 2; }
            case $1 in --repo) REPO=$2 ;; --branch) BRANCH=$2 ;; --dir) DEST=$2 ;; esac; shift 2 ;;
        --dry-run) DRY_RUN=1; ARGS+=("$1"); shift ;;
        --profile) [[ $# -ge 2 ]] || exit 2; ARGS+=("$1" "$2"); shift 2 ;;
        --skip-dependencies|--skip-plugins|--extras) ARGS+=("$1"); shift ;;
        -h|--help) printf 'Usage: bootstrap.sh [--dir ~/.dotfiles] [--repo URL] [--branch main] [installer options]\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done
[[ -z ${SUDO_USER:-} || ${SUDO_USER} == root ]] || { printf 'Run without sudo.\n' >&2; exit 1; }
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
[[ $DEST == /* ]] || { printf 'Use an absolute Linux clone path.\n' >&2; exit 1; }
HOME_PHYSICAL=$(require_linux_path "$HOME")
DEST=$(require_linux_path "$DEST")
[[ $DEST != / && $DEST != "$HOME_PHYSICAL" ]] || { printf 'Choose a dedicated clone directory.\n' >&2; exit 1; }
if [[ -e $DEST || -L $DEST ]]; then
    [[ -d $DEST/.git ]] || { printf 'Existing directory is not a clone; refusing to overwrite: %s\n' "$DEST" >&2; exit 1; }
    printf 'Using existing clone; no automatic pull/reset: %s\n' "$DEST"
elif ((DRY_RUN)); then
    printf 'PREVIEW: install git if needed, clone %s (branch %s) into %s; install dependencies/plugins and back up/link Bash, Zsh, Vim, tmux.\n' "$REPO" "$BRANCH" "$DEST"
    printf 'No files or packages changed. Use --help for installer options.\n'
    exit 0
else
    if ! command -v git >/dev/null 2>&1; then
        . /etc/os-release
        elevate=()
        if ((EUID != 0)); then command -v sudo >/dev/null || { printf 'Install git or sudo first.\n' >&2; exit 1; }; elevate=(sudo); fi
        case ${ID:-} in
            ubuntu) "${elevate[@]}" apt-get update; "${elevate[@]}" apt-get install -y git ca-certificates ;;
            fedora) "${elevate[@]}" dnf install -y git ca-certificates ;;
            *) printf 'Only Ubuntu/Fedora are supported.\n' >&2; exit 1 ;;
        esac
    fi
    git clone --branch "$BRANCH" --single-branch -- "$REPO" "$DEST"
fi
[[ -f $DEST/scripts/install-linux.sh ]] || { printf 'Clone lacks the installer. Commit/push the upgrade first, then pull it here.\n' >&2; exit 1; }
exec bash "$DEST/scripts/install-linux.sh" "${ARGS[@]}"
