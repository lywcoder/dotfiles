# 克隆与配置边界复核（2026-10-25）

## 期望结构

| 环境 | 克隆 | 配置入口的目标 |
| --- | --- | --- |
| 当前 Windows | C:\Users\LYW\dotfiles | 该克隆的 windows 目录 |
| WSL Ubuntu | /home/lyw/.dotfiles（Ubuntu 内） | 该克隆的 Ubuntu 入口与 linux/common |
| WSL Fedora | /home/lyw/.dotfiles（Fedora 内） | 该克隆的 Fedora 入口与 linux/common |
| SSH Linux | 登录用户 HOME 下的 .dotfiles | 服务器自己的克隆 |

Windows 与 Linux 配置独立。Ubuntu/Fedora 共用 Linux 的 Bash、Zsh、Vim、tmux 主要配置，系统入口只处理发行版初始化差异。Git 同步的是仓库内容，不会让两个系统共用同一个磁盘文件。

## 只读核对的实际状态

- Windows 仓库是 C 盘真实目录，当前配置链接目标也在该仓库。
- WSL Ubuntu 四个配置都已链接到 Ubuntu 自己的 /home/lyw/.dotfiles/ubuntu，目标文件系统为 ext4。
- WSL Fedora 的 Zsh/Vim/tmux 已链接到 Fedora 自己的 /home/lyw/.dotfiles/ubuntu，目标文件系统为 ext4；Bash 仍为普通文件。旧入口继续兼容，运行新版安装器后采用 Fedora 入口。
- 现有 SSH Ubuntu 的 Zsh/Vim/tmux 已链接到 /root/.dotfiles/hosts/cloud-ubuntu，文件系统为 ext4；Bash 仍为普通文件。
- 本次未在真实 WSL/SSH HOME 运行安装器；这些独立克隆尚未自动获得 Windows 工作目录中的未发布改动。

## 防止跨系统链接

Windows bootstrap 和安装器只接受 C 盘物理目录；拒绝其他驱动器、UNC/WSL 共享路径，以及路径中的符号链接和 junction。Linux bootstrap 与安装器会先解析真实路径，再验证文件系统；不只根据 /mnt/c 这样的名字判断。共享配置文件和入口必须实际属于当前克隆。

## Arch 支持

现已新增 `arch/` 入口、pacman 分支与独立下载入口，继续使用同一套公共配置和路径规则。支持 Arch 本机、WSL 与 SSH；尚未在真实 Arch HOME 部署。安装与验证范围见 [Arch 指南](arch-linux.md)。

参考：[Arch Zsh 软件包](https://archlinux.org/packages/extra/x86_64/zsh/)、[Arch FZF 软件包](https://archlinux.org/packages/extra/x86_64/fzf/)、[Arch zsh-autosuggestions](https://archlinux.org/packages/extra/any/zsh-autosuggestions/)。

## 本轮验证

Ubuntu/Fedora 各 15 项隔离测试，覆盖克隆、备份、重复运行、配置加载、失败恢复、Windows 文件系统拒绝、符号链接绕过拒绝、公共配置不得逃出克隆，以及旧 tmux 入口加载同一公共文件。Windows 路径测试确认拒绝非 C 盘、WSL/网络路径和目录联接。原生 Windows Vim 通过现有 _vimrc 链接成功加载独立 Windows 文件，脚本加载列表中无 Linux 配置。

真实系统只做只读检查，除本地仓库代码修改外，未重建实际配置链接或改变服务器；尚未提交或推送。
