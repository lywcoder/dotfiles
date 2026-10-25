> 历史记录：本文记录初次建库/迁移时的状态。当前跨系统安装和目录结构以 [安装指南](installation.md) 与 README 为准。

# 远程机器管理

当前云端 Ubuntu 使用 hosts/cloud-ubuntu，服务器本地配置链接至该机器的 ~/.dotfiles。WSL 与服务器共用 linux/common/zsh.zsh，服务器 Bash/Vim/tmux 通过入口复用 ubuntu/ 中的基础配置。

未来新增机器使用中性代号，先只读检查真实文件与依赖，再脱敏和审核，最后备份并链接。不要采集整个家目录，也不要把地址、SSH 用户、IdentityFile、私钥或 known_hosts 放进公共仓库。

共享代码只放可跨机器使用的设置；Windows PATH 处理留在 WSL 层，服务专用别名、凭据与内部路径留在机器仓库外的可选覆盖文件。图形、剪贴板和字体还依赖本机终端。

GitHub 并非自动分发服务。使用 docs/git-sync.md 中的首次接入和日常推送、拉取流程，遇到本地差异先解决，不强制覆盖。部署保留一个有效 SSH 会话，并通过独立连接确认新登录仍可用。
