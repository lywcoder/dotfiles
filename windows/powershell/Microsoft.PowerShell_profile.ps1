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
if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell | Out-String) }
if (Get-Command zoxide -ErrorAction SilentlyContinue) { Invoke-Expression (&zoxide init powershell | Out-String) }

# 加载基础增强模块
# Import-Module posh-git
if (Get-Module -ListAvailable PSReadLine) { Import-Module PSReadLine }

# 检查并加载 FZF 快捷键模块
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# ==============================================================================
# 3. 终端行为配置 (PSReadLine 历史预测)
# ==============================================================================
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    $options = (Get-Command Set-PSReadLineOption).Parameters
    if ($options.ContainsKey('PredictionSource')) { Set-PSReadLineOption -PredictionSource History }
    if ($options.ContainsKey('PredictionViewStyle') -and $PSVersionTable.PSVersion.Major -ge 7) { Set-PSReadLineOption -PredictionViewStyle ListView }
    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -ViModeIndicator Prompt
    if ($options.ContainsKey('HistorySearchCursorMovesToEnd')) { Set-PSReadLineOption -HistorySearchCursorMovesToEnd }
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Remove-Variable options
}

# 4. 别名与自定义函数 (Aliases & Functions)
# ==============================================================================
if (Get-Command lazygit -ErrorAction SilentlyContinue) { Set-Alias lg lazygit }
if (Get-Command eza -ErrorAction SilentlyContinue) { Set-Alias e eza }
if (Get-Command bat -ErrorAction SilentlyContinue) { Set-Alias b bat }
if (Get-Command yazi -ErrorAction SilentlyContinue) { Set-Alias y yazi }

# ==============================================================================
# 5. 自动运行工具 (检测到才运行，防止报错)
# ==============================================================================
# Disabled at startup; run fastfetch manually when needed.
# if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
#     fastfetch
# }

# Coreutils integration; resolve this profile even when opened through a symlink.
$__dotfilesProfile = Get-Item -LiteralPath $PSCommandPath
$__dotfilesDepth = 0
while ($__dotfilesProfile.LinkType -eq 'SymbolicLink') {
    if (++$__dotfilesDepth -gt 16) { throw 'Too many profile symlink levels.' }
    $__dotfilesTarget = [string]$__dotfilesProfile.Target
    if (-not [IO.Path]::IsPathRooted($__dotfilesTarget)) {
        $__dotfilesTarget = Join-Path $__dotfilesProfile.DirectoryName $__dotfilesTarget
    }
    $__dotfilesProfile = Get-Item -LiteralPath $__dotfilesTarget
}
Remove-Variable __dotfilesTarget, __dotfilesDepth -ErrorAction SilentlyContinue
$__dotfilesCoreutils = Join-Path $__dotfilesProfile.DirectoryName 'conf.d\coreutils.ps1'
if (Test-Path -LiteralPath $__dotfilesCoreutils) { . $__dotfilesCoreutils }
Remove-Variable __dotfilesProfile, __dotfilesCoreutils -ErrorAction SilentlyContinue


# BEGIN YAZI PREVIEW FIX
$__yaziPreviewShell = Join-Path $env:APPDATA 'yazi\config\powershell.ps1'
if (Test-Path -LiteralPath $__yaziPreviewShell) { . $__yaziPreviewShell }
Remove-Variable __yaziPreviewShell -ErrorAction SilentlyContinue
# END YAZI PREVIEW FIX

$__dotfilesLocal = Join-Path $HOME '.config/dotfiles/powershell.local.ps1'
if (Test-Path -LiteralPath $__dotfilesLocal) { . $__dotfilesLocal }
Remove-Variable __dotfilesLocal
