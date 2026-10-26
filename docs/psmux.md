# Windows psmux

Windows 使用独立的 `windows/psmux/psmux.conf`，按现有 `linux/common/tmux.conf` 的习惯适配，不直接加载 Linux 配置或 Linux Shell 命令。当前验证版本为 psmux 3.4.0。

## 管理与生效

配置实体：`windows/psmux/psmux.conf`。psmux 首选的用户入口为 `~/.psmux.conf`。
本次实际创建的是一个 `source-file` 加载入口，指向 C 盘仓库中的实体；当前进程没有创建 Windows 符号链接的权限，因此使用此后备方式，没有修改开发者模式。
修改 psmux 时编辑仓库中的配置实体。加载入口不进入 Git，因为每台机器的克隆路径可能不同。

重新配置该入口（不安装软件、不重装 PowerShell 配置）：

```powershell
& "$HOME\dotfiles\scripts\install-psmux.ps1" -DryRun
& "$HOME\dotfiles\scripts\install-psmux.ps1"
```

默认 Auto：可用时创建符号链接；权限不足时创建只含 `source-file` 的加载文件。相同入口重复执行保留，已有配置先备份到 `~/.local/state/dotfiles-backups/psmux-时间-编号/`。
`-Mode SymbolicLink` 只接受符号链接，失败会恢复原入口；`-Mode Loader` 明确使用加载器。真实目录冲突会拒绝操作。
用户已有普通 `.psmux.conf` 被替换时不会丢失，会先备份；现有服务器/会话不会被重载或终止。

Windows 完整安装脚本现包含 psmux（winget 包 `marlocarlo.psmux`）及第六个链接 `~/.psmux.conf`。完整安装仍需符号链接权限以创建其余 PowerShell/Vim 入口；上述单独的 psmux 安装脚本提供无此权限时的后备方式。

启动 `psmux` 后会读取配置。已开启的 psmux 里按 `Ctrl+B`，松开后按 `r` 重载；也可自行在对应会话中执行 `source-file ~/.psmux.conf`。重载 psmux 不会重新启动已经存在的 PowerShell pane。

## 与 Linux 相同的习惯

| 操作 | 按键 |
| --- | --- |
| 前缀 | Ctrl+B |
| 左右分屏 | 前缀后按 `\|` |
| 上下分屏 | 前缀后按 `-` |
| 切换 pane | 前缀后按 h/j/k/l |
| 新窗口，继承目录 | 前缀后按 c |
| 进入复制模式 | 前缀后按 `[` |
| 选择 / 复制 | 复制模式下按 v / y |
| 粘贴缓冲区 | 前缀后按 `]` |
| 重载 psmux 配置 | 前缀后按 r |
| 暂时离开会话 | 前缀后按 d |

鼠标开启、历史 20000 行、窗口与 pane 从 1 编号、自动重编号、Escape 等待 10ms、底部深色状态栏与日期时间，均与 Linux 设置对齐。
Windows pane 明确使用 `pwsh`，不会默认启动 WSL。Linux 的 `if-shell test ...` 私有覆盖段没有照搬到 Windows。
这些设置对齐主要操作习惯；psmux 和 Linux tmux 仍是各自平台上的程序。

## PowerShell 与 fastfetch

`windows/powershell/Microsoft.PowerShell_profile.ps1` 中启动 fastfetch 的 if 段已经整段注释；仍可手动执行 fastfetch。PowerShell 5.1 配置原本没有自动启动 fastfetch。
新开 PowerShell 生效，不必删除 fastfetch 软件。

本机两个 PowerShell 7 PROFILE 入口已核对为指向仓库 `windows/powershell/` 的文件系统符号链接，因此可直接在仓库中编辑。Windows PowerShell 5.1 对应 `windows/windows-powershell/`。
通常从 PROFILE 路径保存也会写到同一实体文件；编辑器采用替换文件的保存方式时可能替换掉链接，可用 Get-Item 检查 LinkType/Target。

```powershell
Get-Item -LiteralPath $PROFILE | Format-List FullName,LinkType,Target
```

配置变动首先改变当前机器的 Git 工作目录，仍需审核、提交、推送，其他机器再拉取；不会自动同步到 GitHub。

## 验证

- 已安装的 psmux 3.4.0 使用临时 HOME、配置自动发现和唯一 `-L` 命名空间验证：设置值、vi 复制绑定、目录继承、重载成功。
- 独立入口安装测试验证只读预览、备份、重复执行、符号链接失败恢复、自动加载器后备、目录冲突拒绝。
- 实际 Windows 用户入口已创建并核对。未自动重载或终止用户的任何现有会话。

可复核：

```powershell
powershell.exe -NoProfile -File tests/test_install_psmux.ps1
python tests/test_psmux_runtime.py
```

依据：[psmux 3.4.0 配置文档](https://github.com/psmux/psmux/blob/v3.4.0/docs/configuration.md)、[兼容性说明](https://github.com/psmux/psmux/blob/v3.4.0/docs/compatibility.md)。
