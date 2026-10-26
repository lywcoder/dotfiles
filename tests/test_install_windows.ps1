$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$temp = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-test-' + [guid]::NewGuid().ToString('N'))
$testHome = Join-Path $temp 'home'
$docs = Join-Path $testHome 'Documents'
New-Item -ItemType Directory -Path $docs -Force | Out-Null
try {
    & (Join-Path $repo 'scripts/install-windows.ps1') -DryRun -SkipDependencies -SkipPlugins -HomeDirectory $testHome -DocumentsDirectory $docs
    if (Test-Path -LiteralPath (Join-Path $testHome '.local')) { throw 'Preview created files.' }
    Set-Content -LiteralPath (Join-Path $testHome '_vimrc') -Value 'old vim config'
    $installer = Join-Path $repo 'scripts/install-windows.ps1'
    & $installer -SkipDependencies -SkipPlugins -HomeDirectory $testHome -DocumentsDirectory $docs
    $item = Get-Item -LiteralPath (Join-Path $testHome '_vimrc') -Force
    if ($item.LinkType -ne 'SymbolicLink') { throw 'Vim symlink missing.' }
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $testHome '.local/state/dotfiles-backups') -Filter 'windows_vim__vimrc' -Recurse)
    if ($backups.Count -ne 1 -or (Get-Content -LiteralPath $backups[0].FullName) -ne 'old vim config') { throw 'Backup verification failed.' }
    & $installer -SkipDependencies -SkipPlugins -HomeDirectory $testHome -DocumentsDirectory $docs
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $testHome '.local/state/dotfiles-backups') -Filter 'windows_vim__vimrc' -Recurse)
    if ($backups.Count -ne 1) { throw 'Repeated install made redundant backups.' }
    foreach ($path in @('PowerShell/profile.ps1', 'PowerShell/Microsoft.PowerShell_profile.ps1', 'WindowsPowerShell/profile.ps1', 'WindowsPowerShell/Microsoft.PowerShell_profile.ps1')) {
        if ((Get-Item -LiteralPath (Join-Path $docs $path)).LinkType -ne 'SymbolicLink') { throw "Missing link: $path" }
    }
    if ((Get-Item -LiteralPath (Join-Path $testHome '.psmux.conf')).LinkType -ne 'SymbolicLink') { throw 'Missing psmux link.' }
    Write-Output 'PASS: preview, six links, backups, repeat install.'
} finally {
    # Only delete the verified, uniquely created test directory. Remove links first.
    $resolved = [IO.Path]::GetFullPath($temp)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolved).StartsWith('dotfiles-test-')) {
        Get-ChildItem -LiteralPath $resolved -Recurse -Force | Where-Object { $_.LinkType } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    } else { throw 'Refusing cleanup outside the test directory.' }
}
