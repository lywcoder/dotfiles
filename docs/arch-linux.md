# Arch Linux 安装

适用于 Arch Linux 本机、WSL Arch 和通过 SSH 登录的 Arch。配置与 Ubuntu/Fedora 共用 `linux/common`；仅包管理、入口目录和发行版初始化有所不同。Windows 配置保持独立。

## 配置与脚本

```text
arch/.bashrc                    加载 linux/common/bash.bash
arch/.zshrc                     加载 linux/common/zsh.zsh 与 WSL 条件处理
arch/.vimrc                     加载 linux/common/vim.vim
arch/.tmux.conf                 兼容入口，动态加载 linux/common/tmux.conf
scripts/download-arch.sh        可单独下载的 Arch 引导入口
scripts/install-arch.sh         已有克隆中的通用 Arch 入口
scripts/install-wsl-arch.sh     已有克隆中的 WSL Arch 入口
scripts/install-ssh-arch.sh     已有克隆中的 SSH Arch 入口
```

上述入口复用 `bootstrap.sh` 和 `install-linux.sh` 的克隆、安装、备份与链接流程。没有复制公共编辑、补全或终端设置。新安装的 tmux 入口直接链接公共文件。

## 新机器：只下载一个入口

先自行更新 Arch 并准备 curl/证书。该步骤会展示系统升级内容供你确认；root 登录时省略 sudo：

```bash
sudo pacman -Syu --needed curl ca-certificates
```

然后下载并预览：

```bash
curl -fL https://raw.githubusercontent.com/lywcoder/dotfiles/main/scripts/download-arch.sh -o /tmp/dotfiles-download-arch.sh
bash /tmp/dotfiles-download-arch.sh --dry-run
```

确认后执行：

```bash
bash /tmp/dotfiles-download-arch.sh
```

下载入口在独立运行时获取公共 bootstrap，再自动克隆仓库并安装。检测到 WSL 时选择 `wsl-arch`，SSH 时选择 `ssh-arch`，普通 Arch 本机选择 `arch`。也可显式指定：

```bash
bash /tmp/dotfiles-download-arch.sh --profile wsl-arch
```

默认克隆到当前用户 `~/.dotfiles`，所有链接均指向本系统这个克隆。自定义位置可加 `--dir "$HOME/src/dotfiles"`；Windows 挂载、网络路径、绕向 Windows 的符号链接会被拒绝。
普通用户不要用 `sudo bash ...`；脚本仅在安装系统包时调用 sudo。实际以 root 登录的服务器管理 /root 自己的配置。

**这些 GitHub 下载命令需要本轮改动提交并推送后才可用。** 尚未发布时，使用本地克隆中的脚本进行预览。

## 已有克隆

先处理本地修改，再拉取包含 Arch 支持的版本：

```bash
git -C "$HOME/.dotfiles" status --short
git -C "$HOME/.dotfiles" pull --ff-only
bash "$HOME/.dotfiles/scripts/install-linux.sh" --dry-run
bash "$HOME/.dotfiles/scripts/install-linux.sh"
```

或运行场景入口：

```bash
bash "$HOME/.dotfiles/scripts/install-wsl-arch.sh" --dry-run
bash "$HOME/.dotfiles/scripts/install-wsl-arch.sh"
```

Arch 本机使用 `install-arch.sh`，SSH 服务器使用 `install-ssh-arch.sh`。这些入口在已有非默认位置的克隆中运行时，要加 `--dir` 指定那个克隆；直接运行 `install-linux.sh` 会安装它所在的克隆版本。

## 依赖与行为

基础包使用官方软件源：

```text
git curl ca-certificates bash bash-completion zsh vim tmux fzf zoxide bat starship eza
```

安装命令为 `pacman -S --needed --noconfirm ...`；不会执行 `pacman -Sy`，也不会自动刷新包数据库或进行全系统升级。先通过 `pacman -Syu` 保持 Arch 更新，避免依赖安装时出现版本或镜像问题；安装失败会在替换配置入口之前停止。
`--extras` 另外尝试 lazygit、yazi、fastfetch。不会启用 AUR、安装 yay/paru 或添加第三方仓库。Starship、eza 直接使用 Arch 官方包。

Zsh 插件下载到 `~/.zsh/plugins`，Vim 插件下载到 `~/.vim/plugged`，vim-plug 下载到 `~/.vim/autoload`；与其他 Linux 使用相同的插件安装与加载方式。有效的已有插件保留，不自动更新。
`realpath`/`findmnt` 由通常预装的 coreutils/util-linux 提供；极简系统缺失时先安装它们。图标字体在终端里自行选择 Nerd Font，原有 Starship 主题保留。

参数：`--dry-run` 只预览、`--skip-dependencies` 不安装系统包、`--skip-plugins` 不下载插件、`--extras` 安装附加工具。需要克隆但 Git 缺失且指定跳过依赖时会停止，提示先安装 Git。
独立下载入口的只读预览仅显示计划，不下载 bootstrap；已经位于克隆中的入口会提供完整路径预览。

## 备份与生效

现有配置先备份到 `~/.local/state/dotfiles-backups/时间-PID/`，再创建链接；相同链接重复执行时保留，链接安装中途失败会尝试恢复原入口。目录冲突、配置源越出克隆会拒绝操作。
不会修改 `.bash_profile`、`.profile`、`.zprofile`，不会切换默认 Shell；Arch Bash 的 `/etc/bash.bashrc` 由系统自动读取。Arch 默认登录文件通常会加载 `.bashrc`，自定义登录文件需自行确认。

安装后新开终端、执行 `zsh` 体验配置，重开 Vim；tmux 可以手动 `tmux source-file ~/.tmux.conf`，不必终止现有会话。Vim 中 `:PlugStatus` 可检查四个插件。
通过符号链接编辑配置会改变本机克隆，跨机器仍需 Git 提交、推送、拉取。

私有覆盖和恢复方法见 [通用安装指南](installation.md)。

## 验证范围

本次在真实 Arch WSL 的临时目录验证了系统识别、脚本语法、Bash 加载及只读安装预览；未在真实 Arch HOME 安装或建链接，也没有运行真实 pacman 安装。
Arch 专项 22 项测试通过：安装分支通过临时 os-release 和模拟 pacman 在具有 Zsh/Vim/tmux 的 Linux 测试主机验证，包含下载入口、克隆、包管理参数、公共配置加载、备份恢复及路径保护；这是安装逻辑验证，不是 Arch 全套依赖安装的实机验收。

开发者可在具备 Bash/Zsh/Vim/tmux 的 Linux 中运行：

```bash
python3 tests/test_install_linux.py
python3 tests/test_arch_install.py
```

依据：[pacman 手册](https://man.archlinux.org/man/pacman.8.en)、[Arch Starship](https://archlinux.org/packages/extra/x86_64/starship/)、[Arch eza](https://archlinux.org/packages/extra/x86_64/eza/)、[Arch Bash 文件清单](https://archlinux.org/packages/core/x86_64/bash/files/)。
