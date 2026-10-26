$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $repo 'scripts/install-psmux.ps1'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-psmux-install-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
$entry = Join-Path $temp '.psmux.conf'
try {
    & $installer -DryRun -HomeDirectory $temp
    if (@(Get-ChildItem -LiteralPath $temp -Force).Count) { throw 'Preview changed the home.' }
    [IO.File]::WriteAllText($entry, 'old psmux config')
    & $installer -Mode Loader -HomeDirectory $temp
    $loader = [IO.File]::ReadAllText($entry)
    if ($loader -notmatch 'source-file.+windows/psmux/psmux.conf') { throw 'Loader does not point to Windows config.' }
    $backupRoot = Join-Path $temp '.local/state/dotfiles-backups'
    $backups = @(Get-ChildItem -LiteralPath $backupRoot -Filter '.psmux.conf' -Recurse -Force)
    if ($backups.Count -ne 1 -or [IO.File]::ReadAllText($backups[0].FullName) -ne 'old psmux config') { throw 'Original config not backed up.' }
    & $installer -Mode Auto -HomeDirectory $temp
    if (@(Get-ChildItem -LiteralPath $backupRoot -Filter '.psmux.conf' -Recurse -Force).Count -ne 1) { throw 'Repeated install created a redundant backup.' }
    # Simulate a machine without symlink privileges regardless of the test account.
    function New-Item {
        [CmdletBinding()]
        param([string]$Path, [string]$ItemType, [object]$Target, [switch]$Force)
        if ($ItemType -eq 'SymbolicLink') { throw 'Simulated symlink privilege failure.' }
        Microsoft.PowerShell.Management\New-Item @PSBoundParameters
    }
    [IO.File]::WriteAllText($entry, 'restore me')
    $failed = $false
    try { & $installer -Mode SymbolicLink -HomeDirectory $temp } catch { $failed = $true }
    if (-not $failed -or [IO.File]::ReadAllText($entry) -ne 'restore me') { throw 'Symlink failure did not restore the original.' }
    & $installer -Mode Auto -HomeDirectory $temp
    if ([IO.File]::ReadAllText($entry) -ne $loader) { throw 'Automatic loader fallback failed.' }
    Remove-Item -LiteralPath Function:\New-Item
    Remove-Item -LiteralPath $entry
    New-Item -ItemType Directory -Path $entry | Out-Null
    $failed = $false
    try { & $installer -HomeDirectory $temp } catch { $failed = $true }
    if (-not $failed) { throw 'Installer replaced a real directory.' }
    Write-Output 'PASS: read-only preview, original backup, idempotency, symlink-failure restore, automatic loader fallback, directory-conflict refusal.'
} finally {
    $resolved = [IO.Path]::GetFullPath($temp)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or -not (Split-Path -Leaf $resolved).StartsWith('dotfiles-psmux-install-')) { throw 'Refusing cleanup outside private test directory.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
