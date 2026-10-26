# Dotfiles

Windows、WSL Ubuntu/Fedora/Arch，以及通过 SSH 使用的 Ubuntu/Fedora/Arch 的个人配置。
仓库地址：https://github.com/lywcoder/dotfiles 。各系统使用自己的本地克隆，通过 Git 同步。

## 支持范围

| 环境 | 自动处理 | 安装入口 |
| --- | --- | --- |
| Windows | PowerShell 7、Windows PowerShell 5.1、Vim、psmux、依赖和配置链接 | `scripts/bootstrap.ps1` |
| WSL Ubuntu | Bash、Zsh、Vim、tmux、依赖和插件 | `scripts/install-wsl-ubuntu.sh` |
| WSL Fedora | 同上，保留 Fedora `/etc/bashrc` 加载 | `scripts/install-wsl-fedora.sh` |
| SSH Ubuntu | 在登录后的服务器本机安装上述 Linux 配置 | `scripts/install-ssh-ubuntu.sh` |
| SSH Fedora | 同上，使用 Fedora 软件包 | `scripts/install-ssh-fedora.sh` |
| Arch Linux 本机 | 共用 Linux 配置，使用 pacman 安装依赖 | `scripts/install-arch.sh` |
| WSL Arch | Bash/Zsh/Vim/tmux、插件与本机链接 | `scripts/install-wsl-arch.sh` |
| SSH Arch | 登录服务器后运行相同 Linux 安装逻辑 | `scripts/install-ssh-arch.sh` |

Windows 只使用 C 盘物理目录中的克隆，当前为 `C:\Users\LYW\dotfiles`。WSL 每个发行版分别在自己的 `~/.dotfiles` 克隆，SSH 在服务器自己的 `~/.dotfiles` 克隆；所有配置链接都指向所在系统的克隆。Linux 安装器会检查真实路径与本地 Linux 文件系统，拒绝 Windows 挂载、网络挂载及源文件逃出克隆。

Ubuntu/Fedora/Arch 共用 `linux/common` 的 Bash、Zsh、tmux、Vim；发行版目录只保留加载入口和系统初始化差异。Windows 使用独立的 `windows` 配置，Vim 不再引用 Linux 文件。

Linux 通用入口是 `scripts/bootstrap.sh`（自动克隆），或克隆后的 `scripts/install-linux.sh`（安装当前工作目录里的版本）。
Windows 原生多路复用使用 psmux；Bash/Zsh 与真正的 Linux tmux 在各自 WSL/SSH 系统中管理。psmux 的配置和快捷键说明见 [Windows psmux](docs/psmux.md)。
不自动创建 WSL 发行版、不配置 SSH 密钥、不改变默认 Shell、不修改 SSH 服务。

Arch 新机器可单独下载 `scripts/download-arch.sh`，自动克隆并安装；命令和 pacman 更新要求见 [Arch 指南](docs/arch-linux.md)。

## 已有仓库先预览

Windows PowerShell：

```powershell
& "$HOME\dotfiles\scripts\install-windows.ps1" -DryRun
```

Ubuntu/Fedora/Arch 的 Linux 终端：

```bash
bash "$HOME/.dotfiles/scripts/install-linux.sh" --dry-run
```

去掉预览参数即可安装。脚本会安装缺失的依赖、下载外部插件、备份并创建配置链接；不同入口及新机器自动克隆命令见 [安装指南](docs/installation.md)。本次升级需要先审核、提交、推送，GitHub 上才会出现新脚本。

## 目录

```text
scripts/                    克隆、依赖安装、备份和链接入口
linux/common/bash.bash      Ubuntu/Fedora/Arch 共用 Bash 行为
linux/common/zsh.zsh        共用 Zsh 历史、补全、工具和插件加载
linux/common/vim.vim        Linux 共用 Vim 设置与四个插件声明
linux/common/tmux.conf      共用 tmux 设置；新安装直接链接这里
ubuntu/                     Ubuntu 入口；保留原路径兼容
fedora/                     Fedora 入口；保留发行版系统加载
arch/                       Arch 入口；共用 Linux 设置
linux/common/wsl.zsh       仅在 WSL 启用的高亮路径处理
windows/                    独立的 PowerShell、coreutils、Vim 与 psmux 配置
hosts/cloud-ubuntu/         已有服务器的兼容入口，供原链接继续使用
examples/                   私有配置位置说明
docs/                       安装、同步与迁移说明
tests/                      临时目录内的安装验证
```

`ubuntu/.tmux.conf`、`fedora/.tmux.conf` 和 `arch/.tmux.conf` 是旧路径兼容加载入口，也会动态加载同一份 `linux/common/tmux.conf`。新脚本直接链接公共文件，不再维护配置副本。

## 功能与同步

Vim：基础编辑设置、lightline、vim-surround、auto-pairs、gruvbox。插件下载到各机器的 `~/.vim` 或 `~/vimfiles`，不进入 Git。Zsh 安装历史建议与 fast-syntax-highlighting；已有系统高亮插件只作为后备，不同时启用两套。

Windows Vim 的设置独立保存在 `windows/vim/vim.vim`；插件与 Linux 可相同，但配置修改互不影响。

默认基础工具包含 Git、Bash/Zsh（Linux）、Vim、tmux（Linux）、FZF、Zoxide、bat 和 Starship；eza 在启用的软件源中可用时安装，否则保留 ls。`--extras` / `-Extras` 额外尝试 lazygit、yazi、fastfetch；Linux 上缺包时明确提示，不自动开启 COPR/PPA。Windows 另外保留 coreutils 集成，并安装 psmux。PowerShell 启动时的 fastfetch 已注释，仍可手动运行。

已有 Starship 主题、Terminal 字体、机器私有配置保留；不同机器原有主题可能不同。新机器没有主题文件时采用 Starship 默认外观。图标需要在 Windows Terminal 中自行选择 Nerd Font。

通过链接编辑配置通常直接改变本机 Git 工作目录；跨系统仍需提交、推送、拉取并重开应用。**Git push 不会自动部署其他机器。** 见 [同步指南](docs/git-sync.md)。

真实凭据、SSH 目录、历史、插件和备份留在仓库外。共享的 Shell 私有设置放 `~/.config/dotfiles/host.sh`；其他覆盖位置见安装指南。不要将 Token 或私钥写进配置后提交。
