# Debian Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Debian support with Ubuntu-equivalent shared configuration without changing Windows paths or live links.

**Architecture:** Keep linux/common authoritative. Add Debian loaders and thin launchers; extend distro/profile/APT selection in the shared installer and bootstrap.

**Tech Stack:** Bash, Python unittest, PowerShell regression checks, WSL isolated HOME fixtures.

**Spec:** docs/superpowers/specs/2026-11-01-debian-support-design.md

## Global Constraints

- Windows stays at C:\Users\LYW\dotfiles; no Windows source/default/link changes.
- Linux clone defaults remain ~/.dotfiles on the local Linux filesystem.
- No actual HOME deployment, dependency installation, remote SSH access or push.
- Preserve existing backup, rollback, plugin and filesystem-boundary behavior.

## Review Focus

- Native Debian without WSL/SSH variables must select `debian`, not `ssh-debian`.
- A Debian profile on another distro must fail before changing any HOME entry.
- Missing initial Git must use apt while --skip-dependencies must install nothing.
- Package/plugin failures must leave original configuration entries untouched.
- Download preview must perform no network/filesystem writes, including on a minimal system.

## Task 1: Debian installer and loaders

**Files:** tests/test_debian_install.py; scripts/install-linux.sh; debian/.bashrc, .zshrc, .vimrc, .tmux.conf.
**Interfaces:** preserve install-linux.sh flags; add debian/wsl-debian/ssh-debian profiles and ID=debian.

- [x] Add failing Debian fixture integration tests for three profiles, native autodetection, shared runtime, backup/repeat/rollback and APT selection. Reuse existing integration harness.
- [x] Run the new tests and confirm failure is unsupported Debian, not environment setup.
- [x] Add Debian loaders using the existing Ubuntu loader contents. Extend distro/profile validation, native selection and both APT branches.
- [x] Run the Debian suite and confirm behavior including existing boundary tests.

## Task 2: Bootstrap and launchers

**Files:** scripts/bootstrap.sh; scripts/install-debian.sh, install-wsl-debian.sh, install-ssh-debian.sh, download-debian.sh; tests/test_debian_install.py.
**Interfaces:** existing bootstrap flags and --dir/--repo remain unchanged; download-debian.sh accepts installer flags.

- [x] Add failing tests for existing-clone launchers, standalone read-only preview, initial Git via APT, missing optional package, package failure, and profile mismatch.
- [x] Extend bootstrap's initial Git branch and add thin launchers, following the Arch standalone download pattern.
- [x] Verify launchers use only the selected local Linux clone and no live HOME.

## Task 3: Documentation and regression

**Files:** README.md; docs/installation.md; docs/debian-linux.md; tests/test_install_linux.py.
**Interfaces:** document Debian commands and retained Windows default; include Debian in common tmux runtime coverage.

- [x] Document Debian native/WSL/SSH setup and shared behavior; explicitly state download URLs need publication first.
- [x] Run Python integration discovery on Ubuntu/Fedora/Arch and Debian where runtime tools permit; run shell syntax checks and Windows path-boundary checks.
- [x] Review full diff; verify Windows source bytes, defaults and live entrypoints remain unchanged.
- [x] Apply only reviewed feature files to original repository after checking it still matches the baseline; leave changes uncommitted for review.

Execution note: the user already approved implementation. Use a standalone staging copy in the writable chat workspace, then guarded file-by-file application to the original checkout. Do not create/move the live repository or change its branch. Repository commits/push are deferred to the user.
