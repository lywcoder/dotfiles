[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateSet('Auto', 'SymbolicLink', 'Loader')]
    [string]$Mode = 'Auto',
    [string]$HomeDirectory = $HOME
)
$ErrorActionPreference = 'Stop'
# Only this Windows entry is changed; no dependencies or other profiles are installed.
$repoRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if ([IO.Path]::GetPathRoot($repoRoot) -ine 'C:\') { throw 'Windows dotfiles must reside on C:.' }
$source = Join-Path $repoRoot 'windows/psmux/psmux.conf'
$probePath = $source
while ($probePath) {
    $item = Get-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Use a physical C: repository path: $probePath" }
    $parent = Split-Path -Parent $probePath
    if ($parent -eq $probePath) { break }
    $probePath = $parent
}
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Missing config: $source" }
$HomeDirectory = [IO.Path]::GetFullPath($HomeDirectory)
if (-not (Test-Path -LiteralPath $HomeDirectory -PathType Container)) { throw 'HomeDirectory must exist.' }
$destination = Join-Path $HomeDirectory '.psmux.conf'
$quotedSource = $source.Replace('\', '/').Replace('"', '\"')
$loader = "# Managed entry; edit the config in dotfiles, not this loader.`nsource-file `"$quotedSource`"`n"
$existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
if ($existing -and $existing.PSIsContainer) { throw "Refusing to replace a directory: $destination" }
if ($DryRun) { Write-Output "PREVIEW $destination -> $source (mode $Mode; back up existing entry)"; return }
if ($existing -and $existing.LinkType -eq 'SymbolicLink' -and [string]$existing.Target -eq $source -and $Mode -ne 'Loader') {
    Write-Output "OK symbolic link: $destination -> $source"; return
}
if ($existing -and -not $existing.LinkType -and [IO.File]::ReadAllText($destination) -eq $loader -and $Mode -ne 'SymbolicLink') {
    Write-Output "OK source-file loader: $destination -> $source"; return
}
$backupRoot = Join-Path $HomeDirectory ('.local/state/dotfiles-backups/psmux-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
$backupPath = Join-Path $backupRoot '.psmux.conf'
$saved = $false
$created = $false
try {
    if ($existing) { Move-Item -LiteralPath $destination -Destination $backupPath; $saved = $true }
    $linked = $false
    if ($Mode -ne 'Loader') {
        try {
            New-Item -ItemType SymbolicLink -Path $destination -Target $source -ErrorAction Stop | Out-Null
            $linked = $true
            $created = $true
        } catch {
            if ($Mode -eq 'SymbolicLink') { throw }
            if (Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue) { throw 'Link attempt left an entry behind; inspect it before retrying.' }
            Write-Output 'Symbolic link unavailable; using a source-file loader to the same repository file.'
        }
    }
    if (-not $linked) {
        [IO.File]::WriteAllText($destination, $loader, (New-Object System.Text.UTF8Encoding($false)))
        $created = $true
    }
    $entryType = if ($linked) { 'symbolic link' } else { 'source-file loader' }
    Write-Output "Configured $entryType`: $destination -> $source"
    if ($saved) { Write-Output "Previous entry backed up: $backupPath" }
} catch {
    if ($created) { Remove-Item -LiteralPath $destination -Force }
    if ($saved) { Move-Item -LiteralPath $backupPath -Destination $destination }
    throw
}
Write-Output 'New psmux sessions load this entry. Existing sessions were not reloaded or restarted.'
