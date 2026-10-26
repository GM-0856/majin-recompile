param([switch]$Preview, [switch]$Baseline)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$build=Join-Path $root 'prototype/out/build/win-amd64-1080p-probe'
# Both modes use identical tracing code; only the guarded startup mutation differs.
$exe=Join-Path $build 'majin.exe'
if(!(Test-Path $exe)){throw 'Build the isolated 1080p probe first.'}
$testRoot=Join-Path $root 'private/runtime-1080p-probe'
$launchArgs=@(& (Join-Path $PSScriptRoot 'run.ps1') -WindowSize '1920x1080' -Fullscreen $false -RenderScale 1 -InputMode Controller -Preview | Where-Object {$_ -notlike 'Runtime log:*'})
foreach($option in @('--user_data_root','--cache_root','--metadata_root')) {
    $index=[Array]::IndexOf($launchArgs,$option)
    if($index -lt 0){throw "Missing option $option"}
    $leaf=@{'--user_data_root'='user';'--cache_root'='cache';'--metadata_root'='metadata'}[$option]
    $launchArgs[$index+1]=Join-Path $testRoot $leaf
}
$logIndex=[Array]::IndexOf($launchArgs,'--log_file')
$kind=if($Baseline){'baseline'}else{'probe'}
$launchArgs[$logIndex+1]=Join-Path $root ('reports/resolution-'+$kind+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
if($Preview){$exe; $launchArgs; return}
if(Get-Process majin -ErrorAction SilentlyContinue){throw 'Close Majin before starting the isolated probe.'}
New-Item -ItemType Directory -Force $testRoot | Out-Null
$testUser=Join-Path $testRoot 'user'
if(!(Test-Path $testUser)){
    $originalUser=Join-Path $root 'private/runtime/user'
    if(Test-Path $originalUser){Copy-Item -LiteralPath $originalUser -Destination $testUser -Recurse}
}
$quoted=@($launchArgs | ForEach-Object { '"' + (($_ -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"' })
$previousTrace=$env:MAJIN_RESOLUTION_TRACE
$previousStartup=$env:MAJIN_1080P_STARTUP
try {
    $env:MAJIN_RESOLUTION_TRACE='1'
    $env:MAJIN_1080P_STARTUP=if($Baseline){'0'}else{'1'}
    $process=Start-Process -FilePath $exe -WorkingDirectory $build -ArgumentList $quoted -Wait -PassThru
} finally {
    $env:MAJIN_RESOLUTION_TRACE=$previousTrace
    $env:MAJIN_1080P_STARTUP=$previousStartup
}
if($null -ne $process.ExitCode -and $process.ExitCode -ne 0){throw "1080p probe exited with $($process.ExitCode)"}
