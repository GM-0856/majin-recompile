param([switch]$Force)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$paths = @('debug', 'release') | ForEach-Object {
    Join-Path $projectRoot "prototype/out/build/win-amd64-$_/majin.exe"
}
$targets = @(Get-Process -Name majin -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -and $paths -contains $_.Path
})
if (-not $targets.Count) {
    Write-Output 'Nenhuma instancia deste prototipo esta aberta.'
    return
}
foreach ($target in $targets) {
    if ($Force) {
        Stop-Process -Id $target.Id
        Write-Output "Encerramento forcado solicitado: $($target.Id)."
    } elseif ($target.CloseMainWindow()) {
        Write-Output "Fechamento normal solicitado: $($target.Id)."
    } else {
        Write-Warning 'Nao foi possivel solicitar fechamento. Se estiver travado, use -Force. Progresso nao salvo pode ser perdido.'
    }
}
