[CmdletBinding()]
param(
    [string]$Repository = 'https://github.com/lywcoder/dotfiles.git',
    [string]$Branch = 'main',
    [string]$Directory = '',
    [switch]$DryRun,
    [switch]$SkipDependencies,
    [switch]$SkipPlugins,
    [switch]$Extras
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
if (-not $Directory) { $Directory = Get-DotfilesWindowsDefaultPath }
$Directory = Assert-DotfilesWindowsPath $Directory
if ($Directory -eq [IO.Path]::GetPathRoot($Directory) -or $Directory -eq $HOME) { throw 'Choose a dedicated clone directory.' }
if (Test-Path -LiteralPath $Directory) {
    if (-not (Test-Path -LiteralPath (Join-Path $Directory '.git') -PathType Container)) { throw 'Existing directory is not a clone; refusing to overwrite it.' }
    Write-Output "Using existing clone without automatic pull/reset: $Directory"
} elseif ($DryRun) {
    Write-Output "PREVIEW: install Git if needed; clone $Repository ($Branch) into $Directory; install Windows dependencies/plugins, back up and link profiles/Vim."
    return
} else {
    if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'Install Git or App Installer (winget) first.' }
        & winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) { throw 'Git installation failed.' }
        $env:PATH = $env:PATH + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
        if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) { throw 'Git installed; reopen PowerShell and run this command again.' }
    }
    & git clone --branch $Branch --single-branch -- $Repository $Directory
    if ($LASTEXITCODE -ne 0) { throw 'Clone failed.' }
}
$installer = Join-Path $Directory 'scripts/install-windows.ps1'
if (-not (Test-Path -LiteralPath $installer)) { throw 'Clone lacks the installer. Commit/push the upgrade first, then pull it here.' }
& $installer -DryRun:$DryRun -SkipDependencies:$SkipDependencies -SkipPlugins:$SkipPlugins -Extras:$Extras
