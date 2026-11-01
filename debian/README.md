# Debian 配置入口

这四个入口与 Ubuntu 使用相同的 `linux/common` Bash、Zsh、Vim、tmux 设置。
它们按入口文件的真实位置解析仓库，不依赖 Windows 路径。

新安装器将 `~/.tmux.conf` 直接链接到 `linux/common/tmux.conf`；这里的
`.tmux.conf` 也可用于手动链接，并动态加载同一份公共文件。

本机、WSL、SSH 安装与下载步骤见 [Debian 指南](../docs/debian-linux.md)。
Linux 默认克隆到本系统的 `~/.dotfiles`；Windows 继续使用 `C:\Users\LYW\dotfiles`。
