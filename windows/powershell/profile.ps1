# Optional Conda hook. Set DOTFILES_CONDA_EXE for a different installation.
$__dotfilesConda = $env:DOTFILES_CONDA_EXE
if (-not $__dotfilesConda) { $__dotfilesConda = 'D:\Anaconda\Anaconda\Scripts\conda.exe' }
if (Test-Path -LiteralPath $__dotfilesConda) {
    (& $__dotfilesConda 'shell.powershell' 'hook') | Out-String | Where-Object { $_ } | Invoke-Expression
}
Remove-Variable __dotfilesConda
