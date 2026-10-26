# 安装与升级

这些脚本会在执行它们的系统中安装配置。SSH 机器请先自行登录，再执行 Linux 命令；Windows 脚本不会登录服务器，也不会修改其他 WSL 发行版。

## 本次升级发布前

先在 Windows 审核 `git status --short` 和改动，包括未跟踪文件。新脚本尚未推送时，下面 GitHub 下载地址不存在。
已有本地仓库可以直接使用 `install-*` 入口测试/预览；本次不自动提交或推送。

## Windows 新机器

前提：Windows 10/11、PowerShell 5.1 或 7，App Installer 提供的 winget，以及网络。
先启用 Windows 开发者模式以允许普通账户创建符号链接；也可在同一账户的管理员 PowerShell 执行。
不要换用另一个管理员账户，否则 HOME、文档目录和软件安装范围都会变化。

```powershell
$setup = Join-Path $env:TEMP 'dotfiles-bootstrap.ps1'
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/lywcoder/dotfiles/main/scripts/bootstrap.ps1' -OutFile $setup
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup -DryRun
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setup
```

当用户 HOME 位于 C 盘时，默认克隆到 `$HOME\dotfiles`；否则默认使用 `C:\dotfiles\用户名\repo`。`-Directory 'C:\code\dotfiles'` 可换位置，但必须仍在 C 盘物理目录中；D 盘、UNC、WSL 共享路径，以及路径中的符号链接/目录联接都会被拒绝。ExecutionPolicy Bypass 只用于这次启动的进程，不修改持久策略。
Git 缺失时先用 winget 安装；若新 PATH 尚未可见，按提示重开 PowerShell 后重试。
Windows 不强制搬迁已有克隆，不覆盖目录；已有克隆不会自动 pull/reset。

winget 安装：Git、PowerShell 7、Vim、Starship、Zoxide、FZF、eza、bat、uutils coreutils、psmux。
PSReadLine 和 PSFzf 使用 PSGallery 的 CurrentUser 范围；第一次访问仓库、NuGet 或软件安装可能出现系统提示。
Windows PowerShell 5.1 保持较轻量的原配置；PowerShell 7 提供完整的预测/快捷键配置。两者都使用真正的 Vim，不再把 `vim` 偷换成 `nvim`。

## Windows psmux

Windows 完整安装包含 psmux 及配置链接。只给现有 psmux 接入配置可运行 `scripts/install-psmux.ps1`，支持无符号链接权限时的 source-file 加载器后备；详见 [psmux 指南](psmux.md)。PowerShell 的 fastfetch 启动段已注释。

## WSL Ubuntu / SSH Ubuntu 新机器

需要 curl 和 CA 证书；最小系统缺失时先执行：

```bash
sudo apt-get update
sudo apt-get install -y curl ca-certificates
```

SSH 以 root 登录时可省略 sudo。然后：

```bash
curl -fL https://raw.githubusercontent.com/lywcoder/dotfiles/main/scripts/bootstrap.sh -o /tmp/dotfiles-bootstrap.sh
bash /tmp/dotfiles-bootstrap.sh --profile wsl-ubuntu --dry-run
bash /tmp/dotfiles-bootstrap.sh --profile wsl-ubuntu
```

SSH Ubuntu 把 `wsl-ubuntu` 换成 `ssh-ubuntu`。也可以省略 `--profile`，脚本自动检测 Ubuntu/Fedora/Arch 与 WSL。

## WSL Fedora / SSH Fedora 新机器

缺少 curl 时先执行 `sudo dnf install -y curl ca-certificates`。然后：

```bash
curl -fL https://raw.githubusercontent.com/lywcoder/dotfiles/main/scripts/bootstrap.sh -o /tmp/dotfiles-bootstrap.sh
bash /tmp/dotfiles-bootstrap.sh --profile wsl-fedora --dry-run
bash /tmp/dotfiles-bootstrap.sh --profile wsl-fedora
```

SSH Fedora 把 `wsl-fedora` 换成 `ssh-fedora`。Fedora 的 `.bashrc` 会先读取 `/etc/bashrc`，再加载共享配置。

所有 Linux 默认克隆到各自系统内的 `~/.dotfiles`，可用 `--dir "$HOME/src/dotfiles"` 改位置。Ubuntu WSL、Fedora WSL 和 SSH 服务器各有自己的克隆，即使路径文字相同，文件也是独立的。
安装前解析真实路径并用 `findmnt` 检查文件系统；只接受 ext2/ext3/ext4、btrfs、xfs、zfs、f2fs、bcachefs、overlay、tmpfs、ramfs。Windows 的 9p/DrvFS/NTFS、网络存储、未识别的文件系统均会拒绝。通过 Linux 名称的符号链接绕到 Windows，同样会拒绝。
`realpath`、`findmnt` 通常由 coreutils/util-linux 预装；最小系统缺失时先安装这两个基础包。配置源文件还必须实际位于当前克隆内，不允许链接到外部文件。旧的 HOME 配置链接可以备份并替换，但不会沿旧链接改写原目标。
普通用户直接执行脚本；脚本只在安装系统软件包时调用 sudo。不要用 `sudo bash ...` 给普通账户装配置；真正的 root 登录则管理 /root 自己的配置。

Linux 基础依赖使用 apt/dnf。Ubuntu 包为 `vim`、Fedora 包为 `vim-enhanced`；Ubuntu 的 bat 命令可用 batcat，配置会兼容。
Starship 缺失时从官方安装器下载至 `~/.local/bin`，不添加第三方软件源。eza/可选工具不在启用软件源时会提示缺失，并使用后备行为；不会隐式切换第三方源。

## Arch Linux（本机、WSL、SSH）

使用可单独下载的 `scripts/download-arch.sh`，或克隆内的 `install-arch.sh` / `install-wsl-arch.sh` / `install-ssh-arch.sh`。它们复用公共配置、备份与链接逻辑；Arch 通过 pacman 官方源安装依赖。先自行 `pacman -Syu` 更新，安装器不执行单独的 `-Sy` 或全系统升级。完整命令见 [Arch 安装指南](arch-linux.md)。

## 已有克隆，包括你现在的 Ubuntu 和 Fedora

先检查并同步，处理本地未提交修改后再拉取：

```bash
git -C "$HOME/.dotfiles" status --short
git -C "$HOME/.dotfiles" pull --ff-only
bash "$HOME/.dotfiles/scripts/install-linux.sh" --dry-run
bash "$HOME/.dotfiles/scripts/install-linux.sh"
```

也可使用对应入口：

```bash
bash "$HOME/.dotfiles/scripts/install-wsl-fedora.sh" --dry-run
```

四个场景入口都复用 bootstrap，默认选 `~/.dotfiles`。自定义克隆路径时，使用该克隆的 `install-linux.sh`，或给场景入口加 `--dir "$HOME/自定义路径"`。

Windows 已有克隆：

```powershell
& "$HOME\dotfiles\scripts\install-windows.ps1" -DryRun
& "$HOME\dotfiles\scripts\install-windows.ps1"
```

## 参数、边界与恢复

| Linux | Windows | 用途 |
| --- | --- | --- |
| `--dry-run` | `-DryRun` | 只预览，不创建文件、不下载、不装软件 |
| `--skip-dependencies` | `-SkipDependencies` | 不使用系统包管理器或安装 PowerShell 模块 |
| `--skip-plugins` | `-SkipPlugins` | 不下载 Vim/Zsh 插件 |
| `--extras` | `-Extras` | 另外尝试安装 lazygit、yazi、fastfetch |

安装器保留已有非空插件目录，不自动更新插件。首次下载使用上游当时版本，不承诺所有机器有相同插件版本；如需完全可复现，可后续引入版本锁定。Vim 可用 `:PlugStatus` 查看插件，`:PlugUpdate` 主动更新。

只管理当前用户的四个 Linux 配置入口，或 Windows 六个入口（含 ~/.psmux.conf）。已有正确链接直接保留；普通文件、旧链接、失效链接先移动到私有备份目录，然后创建新链接。真实目录冲突会拒绝安装。链接阶段失败会尝试恢复该阶段已经替换的入口。不会清理旧备份或旧插件。

备份在各系统用户目录的 `.local/state/dotfiles-backups/时间-PID/`，Linux 权限 700。依赖/插件安装先于链接；下载失败不会开始替换入口。恢复配置不会卸载软件包或删除新下载的插件。

Linux 恢复某个文件，先确认备份目录和原文件：

```bash
ls -la "$HOME/.local/state/dotfiles-backups/具体备份目录"
unlink "$HOME/.bashrc"
mv -T "$HOME/.local/state/dotfiles-backups/具体备份目录/.bashrc" "$HOME/.bashrc"
```

只在 `.bashrc` 仍是安装器创建的链接时执行 unlink。旧链接备份指向的实体文件仍在原位置；若实体文件后来被移动，需要先恢复其位置。
Windows 在确认目标仍是链接后用 Remove-Item 删除该链接，再用 Move-Item 放回备份文件。不要递归删除配置目录。

不改 `.profile` / `.bash_profile` / `.zprofile`，保留发行版登录初始化。常规 Ubuntu/Fedora 默认登录文件会加载 `.bashrc`；自定义登录文件若没加载，请自行补上 `[ ! -r "$HOME/.bashrc" ] || . "$HOME/.bashrc"`。当前默认 Shell 不会切换；执行 `zsh` 可尝试配置，确认后再自行决定是否 chsh。
当前已打开的 Shell/Vim/tmux 不强制重载。新开终端、重开 Vim；tmux 可用 `tmux source-file ~/.tmux.conf`，既有会话无须杀掉。

## 配置共享边界

Ubuntu、Fedora 与 Arch 加载同一份 `linux/common/bash.bash`、`zsh.zsh`、`vim.vim` 和 `tmux.conf`。Fedora Bash 额外加载 `/etc/bashrc`，WSL 高亮路径处理只在 WSL 启用；这些是平台适配，不是另外维护一套主要配置。
Windows 只加载 `windows` 目录中的设置；`windows/vim/vim.vim` 独立于 Linux Vim。安装器自动识别 Ubuntu/Fedora/Arch；不能据此保证所有衍生发行版的软件源和包名都相同。

Arch 通过 `arch/` 入口加载公共配置，支持本机、WSL 与 SSH；没有在已有 Arch HOME 执行安装。详见 [Arch 指南](arch-linux.md)。

## 私有覆盖

以下文件都在仓库外，安装器不会生成、覆盖或提交它们：

| 文件 | 用途 |
| --- | --- |
| `~/.config/dotfiles/host.sh` | Bash/Zsh 都能使用的机器私有设置 |
| `~/.config/dotfiles/bash.local.sh` | Bash 专用覆盖 |
| `~/.config/dotfiles/zsh.local.zsh` | Zsh 专用覆盖 |
| `~/.config/dotfiles/vim.local.vim` | Vim 覆盖 |
| `~/.config/dotfiles/tmux.local.conf` | tmux 覆盖 |
| `~/.config/dotfiles/powershell.local.ps1` | Windows PowerShell 覆盖 |
| `~/.config/starship.toml` | 各机器现有 Starship 主题 |

## 验证

```bash
readlink -f ~/.bashrc
readlink -f ~/.zshrc
readlink -f ~/.vimrc
readlink -f ~/.tmux.conf
vim
```

Vim 中执行 `:PlugStatus`。Zsh 中检查 `command -v starship zoxide fzf eza`。
开发验证（不安装真实依赖）：`python3 tests/test_install_linux.py`；分别在 Ubuntu 与 Fedora 执行。Windows：`powershell.exe -NoProfile -File tests/test_install_windows.ps1`，需要符号链接权限；`tests/test_windows_boundaries.ps1` 检查 C 盘路径和目录联接拒绝行为。

文档依据：[Starship 官方安装](https://starship.rs/guide/)、[vim-plug](https://github.com/junegunn/vim-plug)、[WinGet install](https://learn.microsoft.com/en-us/windows/package-manager/winget/install)、[uutils 安装](https://uutils.org/coreutils/docs/installation.html)。
