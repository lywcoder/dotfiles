# Debian：本机、WSL 和 SSH

Debian 的 Bash、Zsh、Vim、tmux 与 Ubuntu 使用同一份 `linux/common` 配置。
`debian/` 只包含加载入口，系统识别仍为 `ID=debian`，不会把 Debian 伪装成 Ubuntu。
APT 安装基础依赖；已有的插件下载、备份、回滚与文件系统边界检查继续复用。

本轮只修改仓库，不在现有用户 HOME 部署。Windows 保持 `C:\Users\LYW\dotfiles`，
现有 Windows/WSL/SSH 配置链接不迁移。不同系统仍各自拥有独立的本机克隆。

## 已有克隆先预览

在 Debian 自己的 Linux 文件系统克隆中运行：

```bash
cd "$HOME/.dotfiles"
bash scripts/install-linux.sh --profile wsl-debian --dry-run
```

确认输出的来源和目标后，去掉 `--dry-run` 安装。按场景选择：

| 环境 | profile | 场景入口 |
| --- | --- | --- |
| Debian 本机 | `debian` | `scripts/install-debian.sh` |
| WSL Debian | `wsl-debian` | `scripts/install-wsl-debian.sh` |
| SSH Debian | `ssh-debian` | `scripts/install-ssh-debian.sh` |

也可省略 profile：WSL 优先检测为 `wsl-debian`；非 WSL 且存在 SSH_CONNECTION 时为
`ssh-debian`；否则为本机 `debian`。SSH 入口由你登录服务器后运行，不会主动连接服务器。

`install-linux.sh` 安装脚本所在克隆的内容；各场景入口走 bootstrap，默认选择
`~/.dotfiles`。如果克隆位于其他目录，请直接使用其 `install-linux.sh`，或给场景入口
加 `--dir "$HOME/实际克隆目录"`。不要在 `/mnt/c` 克隆后直接部署 Linux 配置。

## 新机器下载并配置

**这些新文件需要先提交、推送到 GitHub，以下下载命令才能取得本轮版本。**
本轮不自动提交或推送。新机器的最小前提是 Bash、curl、CA 证书、coreutils、util-linux：

```bash
sudo apt-get update
sudo apt-get install -y curl ca-certificates coreutils util-linux
```

普通用户不要用 `sudo bash` 启动安装器；它只在系统软件包操作时调用 sudo。
真正登录 root 的服务器可省略上述 sudo，配置则属于 `/root`。

```bash
curl -fL https://raw.githubusercontent.com/lywcoder/dotfiles/main/scripts/download-debian.sh -o /tmp/dotfiles-download-debian.sh
bash /tmp/dotfiles-download-debian.sh --profile wsl-debian --dry-run
# 审核后再安装：
bash /tmp/dotfiles-download-debian.sh --profile wsl-debian
```

本机或 SSH 将 profile 换成表中对应值。下载入口在预览时不进行网络访问、克隆、
软件包安装或创建配置链接；执行安装时才下载公共 bootstrap，再克隆和部署。
也支持 `--dir`、`--skip-dependencies`、`--skip-plugins`、`--extras`。

默认克隆到当前用户在本系统内的 `~/.dotfiles`；配置链接必须指向这个 Linux 克隆。
Windows 挂载、网络挂载和通过链接逃出克隆的配置会被拒绝。已有克隆不自动 pull/reset。

## 软件包和插件

基础 APT 包：Git、curl、CA 证书、Bash、bash-completion、Zsh、Vim、tmux、FZF、Zoxide、bat。
Starship 缺失时通过官方安装器装到 `~/.local/bin`；eza 在启用的软件源提供时安装。
`--extras` 另外尝试 lazygit、yazi、fastfetch；可选包缺失会提示，不自动添加第三方源。
不同 Debian 版本的软件包和插件版本可能不同，配置相同不代表外观和版本完全相同。

Vim 插件为 lightline、vim-surround、auto-pairs、gruvbox；Zsh 插件为
zsh-autosuggestions、fast-syntax-highlighting。插件、私有覆盖和备份均留在仓库外。
已有 Starship 主题、默认 Shell、登录文件和当前运行会话不会被更改或强制重载。

## 验证与恢复

```bash
readlink -f ~/.bashrc
readlink -f ~/.zshrc
readlink -f ~/.vimrc
readlink -f ~/.tmux.conf
```

前三项应属于本机克隆的 `debian/`，tmux 应指向其 `linux/common/tmux.conf`。
Vim 使用 `:PlugStatus` 检查插件；重开应用后体验配置。
旧配置备份位于 `~/.local/state/dotfiles-backups/`，恢复方法见 [安装与升级](installation.md)。

开发检查在已有 Bash/Zsh/Vim/tmux/Git/Python 的 Linux 环境运行：

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

测试只操作临时 HOME、克隆和独立 tmux socket；APT、初始 Git 安装和下载失败用离线替身验证，
不真实安装软件包或访问插件网络。Debian 分支可在其他 Linux 测试宿主用 os-release fixture 运行。
实际验证结果见 [本轮验证记录](debian-validation.md)。

参考：[Debian 软件包管理](https://www.debian.org/doc/manuals/debian-reference/ch02.en.html)、
[Debian tmux 软件包](https://packages.debian.org/trixie/tmux)、[Starship 安装](https://starship.rs/guide/)。
