# 跨系统适配升级审核记录

日期：2026-10-25。修改对象：`C:\Users\LYW\dotfiles`。开始时工作目录干净，当前分支已有 GitHub origin；本次不提交、不推送。

## 主要改动

- 新增 Fedora Bash/Zsh/Vim 入口与 tmux 兼容文件；Bash 保留 `/etc/bashrc`。
- 提取 `linux/common/bash.bash`、`vim.vim`、`tmux.conf`；保留 Ubuntu 和旧服务器入口供已有链接继续使用。
- 修复原 `ubuntu/.bashrc` 末尾再次加载同名仓库文件导致的递归。
- Ubuntu/Fedora 共用 Linux Vim；Windows Vim 已独立到 `windows/vim/vim.vim`，两边使用相同四个插件但不互相引用；Windows PowerShell 5.1 不再将 vim 指向配置独立的 nvim。
- 新增 Windows 与四种 WSL/SSH Linux 场景入口，支持自动克隆、依赖、插件、预览、备份、重复执行及链接阶段恢复。
- Linux 克隆默认 `~/.dotfiles`，解析真实路径并验证本地 Linux 文件系统和配置源归属；Windows 仅接受 C 盘物理路径，用户 HOME 在 C 盘时默认 `$HOME\dotfiles`。已有克隆不自动 pull/reset。
- Zsh 在 SSH 中使用较长的按键等待时间；兼容 Fedora 的 FZF 安装路径；高亮插件使用随插件附带的 secondary theme，避免首次启动联网等待。
- PowerShell 缺少工具时跳过对应初始化，修正 PSFzf 参数；Conda 保留已有路径并允许环境变量指定其他位置。
- 重写当前安装/同步说明，旧审计说明标注为历史记录。

## 验证结果与限制

- WSL Ubuntu 26.04.1、WSL Fedora 44：各 15 项离线隔离测试通过（含本轮路径边界和旧 tmux 入口共享测试）。覆盖自动克隆与已有修改保留、只读预览、4 个链接、备份、重复安装、失效链接、目录冲突、发行版错配、中途失败恢复、四个应用加载。包管理器调用使用模拟程序，未安装实际系统软件包。
- 从官方仓库在 Windows 下载插件源码，再复制到 Linux 临时 HOME：两个发行版均成功加载四个 Vim 插件与 gruvbox，以及 Zsh 自动建议和高亮。WSL 直接下载曾超时，尚未验证这台 WSL 的完整在线安装；新机器仍需要能访问 GitHub、Starship 与系统软件源。
- PowerShell 7 与 Windows PowerShell 5.1：所有 `.ps1` 语法检查通过。路径测试确认拒绝 D 盘、UNC/WSL 共享路径及 junction 祖先；原生 Windows Vim 通过现有链接只加载 Windows 配置。
- Windows 实际链接集成测试被当前进程的符号链接权限限制拦下，未替换真实配置；需要开发者模式或同一账户管理员终端。未改系统开发者模式。
- 未连接 SSH 服务器，因此没有在真实远程 Ubuntu/Fedora 上执行部署。SSH 场景使用相同 Linux 安装器，用户登录后在远程执行。
- 当前仓库文件的常见明文密钥/Token 模式扫描无命中，`git diff --check` 通过。该扫描不能证明任意私密内容都不存在，提交前仍应审核新增文件。

## 行为变化与待审核事项

- 共享 Bash 使用 20000 条历史、条件加载 Starship/Zoxide/FZF 和工具别名；没有 Starship 时使用简单的用户/主机/目录提示符。旧 Ubuntu 的桌面通知别名、chroot 提示及标题设置没有复制到共享 Bash。
- 已链接到 Windows 仓库的配置会在下次加载时看到这些代码修改；没有在真实 HOME 执行安装器重新建立链接。Ubuntu/Fedora 自己的独立克隆尚未接收这些改动。
- 新脚本需要先审核、提交并推送，GitHub 的下载地址才会包含这次升级。
- 第一次下载插件使用上游当时版本，尚未实现版本锁定；已有有效插件保留，不自动更新。
- eza 以及 extras 中的软件若不在 Linux 已启用的软件源中会明确提示；不自动添加 COPR/PPA。Windows extras 安装失败会中止，保留原配置入口。
- 不安装字体、不改 Windows Terminal、不搬迁现有 Starship 主题、不改登录文件/默认 Shell/SSH 服务。
- 备份恢复只处理配置文件，不能卸载已经安装的依赖；中断可能留下用户目录里的下载临时文件，需要在确认路径后自行清理。

本次修改前的仓库文件备份保存在当前 Codex 任务的 `work/dotfiles-before-portability`，不进入 dotfiles 或 Git 历史。新脚本运行时生成的配置备份保存在各机器的 `~/.local/state/dotfiles-backups/`。
