param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'game-data.ps1')
$selected=Save-MajinGameDataPath -Path $Path
Write-Output "Game-data folder saved: $selected"
Write-Output 'No game files or saves were moved. The launcher and run.ps1 will use this folder.'