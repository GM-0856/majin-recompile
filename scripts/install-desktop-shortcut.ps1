$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$launcher = Join-Path $PSScriptRoot 'launcher.ps1'
$exe = Join-Path $projectRoot 'prototype/out/build/win-amd64-debug/majin.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw 'Executavel do Majin nao encontrado.' }
$desktop = [Environment]::GetFolderPath('DesktopDirectory')
if (-not $desktop) { throw 'Area de trabalho nao encontrada.' }
$shortcutPath = Join-Path $desktop 'Majin Recompile.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$shortcut.Arguments = '-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $launcher + '"'
$shortcut.WorkingDirectory = $projectRoot
$shortcut.IconLocation = "$exe,0"
$shortcut.Description = 'Abrir Majin. ESC para confirmar encerramento.'
$shortcut.Save()
$check = $shell.CreateShortcut($shortcutPath)
if ($check.Arguments -ne $shortcut.Arguments -or $check.TargetPath -ne $shortcut.TargetPath) {
    throw 'Falha ao verificar atalho.'
}
Write-Output "Atalho criado e verificado: $shortcutPath"
