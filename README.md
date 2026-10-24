# Dotfiles

Windows、WSL Ubuntu 与云端 Ubuntu 的公共配置。真实凭据、SSH 连接资料、机器私有覆盖、历史和备份留在仓库外。

## 当前目录

- `windows/powershell/`、`windows/windows-powershell/`、`windows/vim/`：Windows 原配置通过链接访问这里。
- `linux/common/zsh.zsh`：WSL 与服务器共用的 Zsh 历史、补全、按键、工具与插件初始化。
- `ubuntu/.zshrc`：WSL Zsh 入口；`ubuntu/zsh-wsl.zsh` 保留 Windows 挂载路径相关处理。
- `ubuntu/.bashrc`、`.vimrc`、`.tmux.conf`：WSL 基础配置，同时由服务器入口复用。
- `hosts/cloud-ubuntu/`：云端机器入口文件，加载服务器自己的 `~/.dotfiles` 内的配置。
- `windows/powershell/conf.d/coreutils.ps1`：保留 coreutils 兼容实现，主配置只保留加载逻辑。

## 链接与更新

Windows/WSL 的链接指向 Windows 用户目录下的 dotfiles；服务器链接指向服务器本机的 `~/.dotfiles`。通过链接保存通常直接修改对应机器的仓库文件，某些编辑器会用普通文件替换链接，应留意链接状态。

此次没有提供 GitHub 地址，仓库仍无远程和提交。服务器由已审核文件初始化同样的待审核目录，尚未与本机建立共同提交历史。初次接入以及日常“提交、推送、服务器拉取”的步骤见 `docs/git-sync.md`。仅 push 不会自动更新服务器工作目录或已打开的会话。

## 兼容与私有设置

服务器较旧的 fzf 使用发行版配套脚本；只加载可用的工具和一套高亮插件。服务器 SSH 的 Zsh 等待时间为 50ms，WSL 保留 10ms。服务器 PHP 等私有别名由仓库外的 `~/.config/dotfiles/host.sh` 提供。

Starship 主题在两边原本相同，此次保留。外部插件和软件由各机器自行安装，此次不升级系统软件或删除旧插件。服务器 Vim 采用 WSL 基础编辑行为，旧 Vim 插件保留在磁盘但不自动加载。已有会话不会强制重载。

密钥示例只包含说明，不会自动执行。`.gitignore` 不能替代提交前审核，也无法撤回已经公开的秘密。
