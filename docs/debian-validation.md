# Debian 适配验证记录（2026-11-01）

本轮新增 Debian 配置、安装/下载入口与隔离验证。Windows 仓库仍为
`C:\Users\LYW\dotfiles`，不执行目录改名或活动链接迁移。

## 最终结果

| 实际测试宿主 | 完整 Python 集成套件 | Shell 语法检查 | 实际 HOME 四个配置入口 |
| --- | --- | --- | --- |
| Debian 13 WSL | 65/65 通过 | 通过 | 内容与链接目标未变 |
| Ubuntu WSL | 65/65 通过 | 通过 | 内容与链接目标未变 |
| FedoraLinux-44 WSL | 65/65 通过 | 通过 | 内容与链接目标未变 |
| archlinux WSL | 65/65 通过 | 通过 | 内容与链接目标未变 |

每个宿主运行 `python3 -m unittest discover -s tests -p 'test_*.py' -v`。
Debian 用例 28 项、Arch 用例 22 项、宿主通用用例 15 项，共 260 次最终用例执行。
跨发行版分支使用测试 os-release fixture，不修改宿主的 `/etc/os-release`。

Windows 的 `tests/test_windows_boundaries.ps1` 和 `tests/test_install_psmux.ps1` 通过。
首次在受限进程创建测试目录联接时被拒绝，随后在允许访问私有临时目录的进程中完整重跑通过。
Windows 安装脚本、配置源文件、默认仓库目录和真实用户配置入口保持原样。

## 覆盖内容

- Debian 本机、WSL、SSH profile 的预演与自动识别。
- Bash 历史设置、Zsh 根目录与选项、Vim 显示设置、tmux 历史设置实际加载。
- 四个本机配置链接、原文件备份、重复安装、失效链接备份与链接失败回滚。
- Windows 挂载、间接指向 Windows 的克隆、配置逃出仓库，以及真实目录冲突拒绝。
- 初始 Git 缺失时选择 APT；跳过依赖时不安装 Git。
- 可选包缺失提示；软件包或插件下载失败时保留原配置入口。
- 已有克隆场景入口、独立下载入口的无网络只读预演。
- 独立复核发现 profile 校验过晚：先以两项测试复现，再将 bootstrap 校验前移。
  现在三个 Debian 入口在不匹配的系统上会在克隆/包管理操作前退出；
  多次 `--profile` 也会校验最终生效的值。

## 隔离方式与限制

测试复制项目到 Linux 临时目录，在临时 HOME 内创建链接、私有备份和独立 tmux socket。
APT、Git 初装和插件失败路径使用离线替身，不真实安装软件包或访问插件下载网络。

Debian WSL 原先缺少 tmux。仅用 `apt-get download` 下载官方 tmux 3.5a 和缺少的运行库，
再用 `dpkg-deb -x` 解包到测试专用 `/tmp` 目录；PATH 和动态库路径仅对测试子进程生效，
结束后清理临时目录。不执行 `apt-get install`、`dpkg -i` 或更改系统安装状态。

没有向真实 HOME 部署，也没有连接 SSH 服务器。裸机 Debian 与远端实际 SSH 会话未验证；
本机/SSH 场景通过 profile 和环境模拟检查，实际运行宿主均为 WSL。
不同 Debian 版本的软件源、网络与第三方插件版本仍可能不同。

原始日志位于此次聊天工作目录的 `test-results/`，不将临时路径或测试包加入仓库。
新 GitHub 下载入口需审核、提交并推送后生效；本轮不自动提交或推送。
