# 多机器同步与首次接入 GitHub

符号链接只连接同一台机器的文件路径。Windows/WSL 的原配置链接到本机仓库，服务器的原配置链接到服务器自己的 `~/.dotfiles`。修改任一链接内容，通常直接修改该机器仓库的真实文件；编辑器若替换链接，需要重新核对。

服务器复用 `linux/common/zsh.zsh` 和 `ubuntu/` 中的 Bash/Vim/tmux 基础。共享文件的改动在完成 Git 同步后可影响两边；机器专用入口仅影响相应机器。已经打开的会话通常需要重开或明确重新加载。

完整同步流程：本机修改 → 检查差异和秘密 → git add → git commit → git push → 服务器 git pull --ff-only → 验证并重开相应会话。只推送到 GitHub 不会自动更新服务器工作目录，也不会自动重载应用。

## 当前仓库状态

此次没有 GitHub 地址，因此没有设置远程或推送。Windows 仓库与服务器目录均保持待审核、无提交状态。服务器先由本机已审核内容生成同一份工作目录，并初始化空 Git 仓库；它尚未与 GitHub 建立共同提交历史。

## 首次接入

1. 在 Windows 审核全部文件，包括尚未跟踪的文件；检查 git status，普通 git diff 不显示未跟踪文件。
2. 用户决定 GitHub 仓库后，在本机设置 origin，选择性暂存、提交、推送。
3. 服务器设置同一个 origin。确认没有任何本地提交后，执行 git fetch origin，再检查远程文件清单与当前文件差异。
4. 对此次无提交的服务器仓库，可以用 git reset --mixed origin/main 采用首次提交历史；该命令保留工作文件内容，但更新分支和索引。只适用于确认没有本地提交的首次接入，不要作为日常更新命令。
5. 检查 git status。处理差异后，日常使用 git pull --ff-only 更新。不要用强制重置丢弃机器配置。

真实 IP、SSH 用户、私钥、authorized_keys、机器私有覆盖和备份不进入本仓库。`~/.config/dotfiles/host.sh` 是服务器仓库外的可选覆盖文件。SSH 公钥登录服务器与 GitHub 的仓库访问权限是两件事；本次没有把密钥添加到 GitHub。
