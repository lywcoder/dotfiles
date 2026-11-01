# Debian support design

Approved scope: the user approved steps 1–3 on 2026-11-01 and explicitly excluded steps 4–5.

Add Debian entry files and native/WSL/SSH/download launchers using the existing
Linux installer and bootstrap. Debian and Ubuntu load the same linux/common
Bash, Zsh, Vim and tmux configuration; distribution IDs remain distinct for
profile validation. Debian uses the APT dependency branch, including optional
package availability checks. Existing plugin installation, backup, rollback,
idempotence and Linux filesystem boundaries remain shared.

Add a native `debian` profile alongside `wsl-debian` and `ssh-debian`. Automatic
detection prefers WSL, then a detected SSH connection, then native Debian.
The SSH launcher runs on the already logged-in server and never connects itself.

Windows stays at C:\Users\LYW\dotfiles. Do not change Windows scripts, defaults,
live configuration contents, symbolic links or psmux loaders. Linux continues to
clone into its own ~/.dotfiles. Do not publish, push, switch shells or deploy into
any existing HOME. Tests use temporary clones/HOMEs and simulated package/network
operations; any real runtime test tool must be isolated from system installation.

Acceptance: all Debian profiles preview without mutation; native install creates
four local links and preserves/recover originals; launchers support existing
clones and standalone preview; Debian dependency selection uses apt, never dnf or
pacman; existing Ubuntu/Fedora/Arch behavior passes regression tests. Document
how to preview and install, the need to publish before GitHub download links work,
and actual validation limits.
