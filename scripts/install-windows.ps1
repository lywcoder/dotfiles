[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipDependencies,
    [switch]$SkipPlugins,
    [switch]$Extras,
    [string]$HomeDirectory = $HOME,
    [string]$DocumentsDirectory = [Environment]::GetFolderPath('MyDocuments')
)
$ErrorActionPreference = 'Stop'
# BEGIN Windows repository boundary checks (also embedded in bootstrap/install).
function Assert-DotfilesWindowsPath([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path)) { throw 'Use an absolute path on C:.' }
    $normalized = [IO.Path]::GetFullPath($Path)
    if ([IO.Path]::GetPathRoot($normalized) -ine 'C:\') {
        throw 'Windows dotfiles must reside on C:, not another drive, UNC share or WSL filesystem.'
    }
    $probe = $normalized
    while ($probe) {
        $item = Get-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Repository paths must be physical C: paths, without symlinks/junctions: $probe"
        }
        $parent = Split-Path -Parent $probe
        if ($parent -eq $probe) { break }
        $probe = $parent
    }
    return $normalized
}
function Get-DotfilesWindowsDefaultPath {
    if ($HOME -and [IO.Path]::GetPathRoot($HOME) -ieq 'C:\') { return Join-Path $HOME 'dotfiles' }
    return Join-Path (Join-Path 'C:\dotfiles' $env:USERNAME) 'repo'
}
# END Windows repository boundary checks.
$repoRoot = Assert-DotfilesWindowsPath (Split-Path -Parent $PSScriptRoot)
if (-not $HomeDirectory -or -not $DocumentsDirectory) { throw 'Home/Documents path is unavailable.' }
$HomeDirectory = [IO.Path]::GetFullPath($HomeDirectory)
$DocumentsDirectory = [IO.Path]::GetFullPath($DocumentsDirectory)
# Custom paths support isolated tests; package installs always target the current account.
if (($HomeDirectory -ne $HOME) -and -not $SkipDependencies) { throw 'Custom home requires -SkipDependencies.' }
$links = @(
    @('windows/powershell/profile.ps1', (Join-Path $DocumentsDirectory 'PowerShell/profile.ps1')),
    @('windows/powershell/Microsoft.PowerShell_profile.ps1', (Join-Path $DocumentsDirectory 'PowerShell/Microsoft.PowerShell_profile.ps1')),
    @('windows/windows-powershell/profile.ps1', (Join-Path $DocumentsDirectory 'WindowsPowerShell/profile.ps1')),
    @('windows/windows-powershell/Microsoft.PowerShell_profile.ps1', (Join-Path $DocumentsDirectory 'WindowsPowerShell/Microsoft.PowerShell_profile.ps1')),
    @('windows/vim/_vimrc', (Join-Path $HomeDirectory '_vimrc'))
)
foreach ($managedSource in @('windows/vim/vim.vim', 'windows/powershell/conf.d/coreutils.ps1')) {
    $null = Assert-DotfilesWindowsPath (Join-Path $repoRoot $managedSource)
}
foreach ($link in $links) {
    $null = Assert-DotfilesWindowsPath (Join-Path $repoRoot $link[0])
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $link[0]) -PathType Leaf)) { throw "Missing source: $($link[0])" }
    $item = Get-Item -LiteralPath $link[1] -Force -ErrorAction SilentlyContinue
    if ($item -and $item.PSIsContainer) { throw "Refusing to replace a directory: $($link[1])" }
}
if ($DryRun) {
    Write-Output 'PREVIEW: no downloads, package operations, modules, backups or symlinks.'
    if (-not $SkipDependencies) { Write-Output 'Install missing tools with winget; PSReadLine/PSFzf with CurrentUser scope.' }
    if (-not $SkipPlugins) { Write-Output 'Download vim-plug and four Vim plugins into ~/vimfiles.' }
    foreach ($link in $links) { Write-Output "LINK $($link[1]) -> $(Join-Path $repoRoot $link[0]) (back up existing entry)" }
    return
}
function Refresh-ToolPath {
    $parts = @($env:PATH, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User'))
    $env:PATH = ($parts | Where-Object { $_ }) -join ';'
    # The official Vim installer does not consistently add vim.exe to PATH.
    $vimBases = @((Join-Path $env:ProgramFiles 'Vim'), (Join-Path $env:LOCALAPPDATA 'Programs/Vim'))
    if (${env:ProgramFiles(x86)}) { $vimBases += Join-Path ${env:ProgramFiles(x86)} 'Vim' }
    foreach ($base in $vimBases) {
        if (Test-Path -LiteralPath $base) {
            foreach ($dir in Get-ChildItem -LiteralPath $base -Directory -Filter 'vim*') {
                if (Test-Path -LiteralPath (Join-Path $dir.FullName 'vim.exe')) { $env:PATH += ';' + $dir.FullName }
            }
        }
    }
}
function Install-Tool([string]$CommandName, [string]$PackageId) {
    if (Get-Command $CommandName -CommandType Application -ErrorAction SilentlyContinue) { Write-Output "KEEP $CommandName"; return }
    & winget install --id $PackageId --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "winget failed for $PackageId (exit $LASTEXITCODE)." }
    Refresh-ToolPath
}
# Probe symlink privileges before downloads or replacing actual configuration files.
$backupRoot = Join-Path $HomeDirectory ('.local/state/dotfiles-backups/' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $PID + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
$probe = Join-Path $backupRoot 'symlink-test'
try {
    New-Item -ItemType SymbolicLink -Path $probe -Target (Join-Path $repoRoot 'README.md') | Out-Null
} catch {
    throw 'Cannot create symbolic links. Enable Windows Developer Mode, then rerun as your normal account; or use an elevated PowerShell for that same account.'
} finally {
    if (Get-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue) { Remove-Item -LiteralPath $probe -Force }
}
if (-not $SkipDependencies) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Install App Installer (winget) first.' }
    Refresh-ToolPath
    foreach ($tool in @(
        @('git', 'Git.Git'), @('pwsh', 'Microsoft.PowerShell'), @('vim', 'vim.vim'),
        @('starship', 'Starship.Starship'), @('zoxide', 'ajeetdsouza.zoxide'),
        @('fzf', 'junegunn.fzf'), @('eza', 'eza-community.eza'), @('bat', 'sharkdp.bat'),
        @('coreutils', 'uutils.coreutils')
    )) { Install-Tool $tool[0] $tool[1] }
    if ($Extras) {
        foreach ($tool in @(@('lazygit', 'JesseDuffield.lazygit'), @('yazi', 'sxyazi.yazi'), @('fastfetch', 'Fastfetch-cli.Fastfetch'))) { Install-Tool $tool[0] $tool[1] }
    }
    if (-not (Get-Module -ListAvailable PSReadLine | Where-Object { $_.Version -ge [Version]'2.2.6' })) {
        Install-Module PSReadLine -MinimumVersion 2.2.6 -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    }
    if (-not (Get-Module -ListAvailable PSFzf)) {
        Install-Module PSFzf -Scope CurrentUser -Repository PSGallery -Force
    }
}
function Install-Plugin([string]$Url, [string]$Destination, [string]$RequiredFile) {
    if (Test-Path -LiteralPath $Destination) {
        if (-not (Test-Path -LiteralPath (Join-Path $Destination $RequiredFile) -PathType Leaf)) { throw "Incomplete plugin directory: $Destination" }
        Write-Output "KEEP $Destination"; return
    }
    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $temp = Join-Path $parent ('.dotfiles-download-' + [guid]::NewGuid().ToString('N'))
    & git clone --depth 1 -- $Url $temp
    if ($LASTEXITCODE -ne 0) { throw "Plugin clone failed; inspect $temp" }
    if (-not (Test-Path -LiteralPath (Join-Path $temp $RequiredFile) -PathType Leaf)) { throw "Downloaded plugin lacks $RequiredFile; inspect $temp" }
    Move-Item -LiteralPath $temp -Destination $Destination
}
if (-not $SkipPlugins) {
    if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) { throw 'git is required for plugins.' }
    $vimHome = Join-Path $HomeDirectory 'vimfiles'
    $plug = Join-Path $vimHome 'autoload/plug.vim'
    if (-not (Test-Path -LiteralPath $plug)) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $plug) -Force | Out-Null
        $temp = $plug + '.download-' + [guid]::NewGuid().ToString('N')
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' -OutFile $temp
        Move-Item -LiteralPath $temp -Destination $plug
    }
    foreach ($plugin in @(@('itchyny/lightline.vim', 'lightline.vim', 'autoload/lightline.vim'), @('tpope/vim-surround', 'vim-surround', 'plugin/surround.vim'), @('jiangmiao/auto-pairs', 'auto-pairs', 'plugin/auto-pairs.vim'), @('morhetz/gruvbox', 'gruvbox', 'colors/gruvbox.vim'))) {
        Install-Plugin ('https://github.com/' + $plugin[0] + '.git') (Join-Path $vimHome ('plugged/' + $plugin[1])) $plugin[2]
    }
}
$records = New-Object System.Collections.Generic.List[object]
try {
    foreach ($link in $links) {
        $source = [IO.Path]::GetFullPath((Join-Path $repoRoot $link[0]))
        $dest = $link[1]
        $item = Get-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType -eq 'SymbolicLink' -and [string]$item.Target -eq $source) { Write-Output "OK $dest"; continue }
        $backup = Join-Path $backupRoot ($link[0] -replace '[/\\]', '_')
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
        $record = [pscustomobject]@{ Destination = $dest; Backup = $backup; Source = $source; Saved = $false; Linked = $false }
        $records.Add($record)
        if ($item) { Move-Item -LiteralPath $dest -Destination $backup; $record.Saved = $true }
        New-Item -ItemType SymbolicLink -Path $dest -Target $source | Out-Null
        $record.Linked = $true
        Write-Output "LINK $dest -> $source"
    }
} catch {
    for ($i = $records.Count - 1; $i -ge 0; $i--) {
        $record = $records[$i]
        if ($record.Linked) { Remove-Item -LiteralPath $record.Destination -Force }
        if ($record.Saved) { Move-Item -LiteralPath $record.Backup -Destination $record.Destination }
    }
    throw
}
Write-Output "Complete. Backups: $backupRoot"
Write-Output 'Start a new PowerShell. Existing themes, Conda installations and Terminal settings were preserved.'
Write-Output 'Native Windows uses PowerShell and Vim. Bash/Zsh/tmux belong inside WSL; use the corresponding Linux installer there.'
