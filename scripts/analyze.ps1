$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'reports') | Out-Null
$projectRoot = Split-Path $PSScriptRoot -Parent
$sdkExe = Join-Path $projectRoot 'tools/rexglue-sdk-0.10.0/win-amd64/bin/rexglue.exe'
if (-not (Test-Path -LiteralPath $sdkExe)) { throw 'ReXGlue v0.10.0 SDK not found in tools.' }
Push-Location (Join-Path $projectRoot 'prototype')
try {
    & $sdkExe --log-file '../reports/codegen-latest.log' codegen 'majin_manifest.toml' *> '../reports/codegen-latest-console.txt'
    $result = $LASTEXITCODE
    Get-Content '../reports/codegen-latest-console.txt' -Tail 50
} finally {
    Pop-Location
}
exit $result
