# ================= 1. 基础性能优化 =================
# 禁用一些不必要的检查（如果不需要可以保持现状）

# ================= 2. 核心工具 (优化加载方式) =================
# Starship: 建议只在必要时加载，或者使用预生成的缓存（虽然稍显复杂）
# 这里保持原样，但 Starship 确实是启动慢的大头
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell --print-full-init | Out-String)
}

# Zoxide: 这个工具必带，但我们可以让它稍后初始化
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& zoxide init powershell | Out-String)
}

# ================= 3. 别名与简单函数 (极速加载) =================
# 别名几乎不占用时间，保留
$env:EDITOR = "vim"
# Use real Vim and _vimrc; Neovim requires a separate init.vim.
Set-Alias ll ls
if (Get-Command gsudo -ErrorAction SilentlyContinue) { Set-Alias sudo gsudo }
function grep { findstr @args }

# ================= 4. 模块延迟加载 (关键优化) =================
# 不要直接 Import-Module，因为这会扫描磁盘
# 我们可以利用 PowerShell 的自动加载特性，或者只在环境变量存在时处理
$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"

# PSFzf 往往很重，如果你不是每次打开都要用 FZF，可以考虑注释掉下面这行
# 让 PowerShell 在你第一次运行相关命令时自动尝试加载
# Import-Module PSFzf


# BEGIN YAZI PREVIEW FIX
$__yaziPreviewShell = Join-Path $env:APPDATA 'yazi\config\powershell.ps1'
if (Test-Path -LiteralPath $__yaziPreviewShell) { . $__yaziPreviewShell }
Remove-Variable __yaziPreviewShell -ErrorAction SilentlyContinue
# END YAZI PREVIEW FIX

$__dotfilesLocal = Join-Path $HOME '.config/dotfiles/powershell.local.ps1'
if (Test-Path -LiteralPath $__dotfilesLocal) { . $__dotfilesLocal }
Remove-Variable __dotfilesLocal
