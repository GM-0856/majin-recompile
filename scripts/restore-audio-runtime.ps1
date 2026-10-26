$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$target=Join-Path $root 'prototype/out/build/win-amd64-debug/rexruntimed.dll'
$backup=Join-Path $root 'private/backups/runtime-before-xma-diagnostic/rexruntimed.dll'
if(Get-Process majin -ErrorAction SilentlyContinue){throw 'Close Majin before restoring the runtime.'}
if(!(Test-Path -LiteralPath $backup)){throw 'Original runtime backup not found.'}
Copy-Item -LiteralPath $backup -Destination $target -Force
if((Get-FileHash $target).Hash -ne (Get-FileHash $backup).Hash){throw 'Runtime verification failed.'}
Write-Output 'Original runtime restored.'
