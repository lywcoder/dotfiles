# ==============================================================================
# 1. 环境变量配置
# ==============================================================================
$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
$env:EDITOR = "vim"

# ==============================================================================
# 2. 工具与模块加载 (Starship / Zoxide / PSFzf)
# ==============================================================================
# 选装高颜值主题样式（这里以经典且好看的 preset gruvbox-rainbow 为例，也可换成 tokio-night）
# 首次加载时设置预设环境变量，既不影响启动速度，又能大幅拉满颜值 
$env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"

# 初始化 提示符 (Starship) 与 路径跳转 (Zoxide)
Invoke-Expression (&starship init powershell | Out-String)
Invoke-Expression (&zoxide init powershell | Out-String)

# 加载基础增强模块
# Import-Module posh-git
Import-Module PSReadLine

# 检查并加载 FZF 快捷键模块
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineKeyHandler
}

# ==============================================================================
# 3. 终端行为配置 (PSReadLine 历史预测)
# ==============================================================================
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView  # 列表模式展示历史命令
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -ViModeIndicator Prompt 
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# 4. 别名与自定义函数 (Aliases & Functions)
# ==============================================================================
Set-Alias lg lazygit
Set-Alias e eza
Set-Alias b bat
Set-Alias y yazi

# ==============================================================================
# 5. 自动运行工具 (检测到才运行，防止报错)
# ==============================================================================
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch
}

# Coreutils integration; resolve this profile even when opened through a symlink.
$__dotfilesProfile = Get-Item -LiteralPath $PSCommandPath
if ($__dotfilesProfile.LinkType -eq 'SymbolicLink') {
    $__dotfilesProfile = $__dotfilesProfile.ResolveLinkTarget($true)
}
$__dotfilesCoreutils = Join-Path $__dotfilesProfile.DirectoryName 'conf.d\coreutils.ps1'
if (Test-Path -LiteralPath $__dotfilesCoreutils) { . $__dotfilesCoreutils }
Remove-Variable __dotfilesProfile, __dotfilesCoreutils -ErrorAction SilentlyContinue


# BEGIN YAZI PREVIEW FIX
$__yaziPreviewShell = Join-Path $env:APPDATA 'yazi\config\powershell.ps1'
if (Test-Path -LiteralPath $__yaziPreviewShell) { . $__yaziPreviewShell }
Remove-Variable __yaziPreviewShell -ErrorAction SilentlyContinue
# END YAZI PREVIEW FIX
