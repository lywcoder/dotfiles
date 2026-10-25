$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$bootstrap = Join-Path $repo 'scripts/bootstrap.ps1'
foreach ($path in @('D:\dotfiles', '\\wsl.localhost\Ubuntu\home\lyw\.dotfiles', '\\server\share\dotfiles')) {
    $failed = $false
    try { & $bootstrap -Directory $path -DryRun } catch { $failed = $true; Write-Output "PASS refused: $path" }
    if (-not $failed) { throw "Accepted forbidden clone path: $path" }
}
$messages = @(& $bootstrap -Directory $repo -DryRun)
if (-not ($messages -match [regex]::Escape($repo))) { throw 'Expected current C: repository.' }
Write-Output 'PASS C: repository preview.'
# Execute only the pure validation functions to test a C: junction to another directory.
$tree = [System.Management.Automation.Language.Parser]::ParseFile($bootstrap, [ref]$null, [ref]$null)
$function = $tree.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-DotfilesWindowsPath'}, $true)
Invoke-Expression $function.Extent.Text
$root = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-boundary-' + [guid]::NewGuid().ToString('N'))
$target = Join-Path $root 'target'
$junction = Join-Path $root 'junction'
New-Item -ItemType Directory -Path $target -Force | Out-Null
try {
    New-Item -ItemType Junction -Path $junction -Target $target | Out-Null
    $failed = $false
    try { $null = Assert-DotfilesWindowsPath (Join-Path $junction 'repo') } catch { $failed = $true }
    if (-not $failed) { throw 'Accepted a junction in the clone path.' }
    Write-Output 'PASS refused junction ancestor.'
} finally {
    if (Get-Item -LiteralPath $junction -Force -ErrorAction SilentlyContinue) { Remove-Item -LiteralPath $junction -Force }
    # Both known empty directories are removed non-recursively.
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target }
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root }
}
