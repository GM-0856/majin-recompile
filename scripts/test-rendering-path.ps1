param([string]$GameDataRoot)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$GameDataRoot){$GameDataRoot=Join-Path $root 'private/game-data'}
$fixture=Join-Path $env:TEMP ('Majin rendering test '+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts'),(Join-Path $fixture 'prototype/out/build/win-amd64-release') -Force | Out-Null
foreach($name in @('run.ps1','game-data.ps1','frame-rate.ps1','diagnostics-common.ps1','performance-metrics.cs')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $fixture 'scripts')}
Set-Content -LiteralPath (Join-Path $fixture 'prototype/out/build/win-amd64-release/majin.exe') -Value 'Test placeholder. Never executed.'
$runner=Join-Path $fixture 'scripts/run.ps1'
function Assert($value,$message){if(!$value){throw $message}}
function Arg($list,$key){$i=[Array]::IndexOf($list,$key);Assert ($i -ge 0) "Missing $key";return $list[$i+1]}
$default=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -Preview)
$rov=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -RenderingPath ROV -Preview)
$repeat=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -RenderingPath ROV -Preview)
$scaled=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -RenderingPath ROV -RenderScale 2 -Preview)
Assert ($default -contains '--render_target_path_d3d12=') 'Default did not restore automatic backend selection'
Assert ($rov -contains '--render_target_path_d3d12=rov') 'ROV not forwarded'
Assert ($default -contains '--gpu_allow_invalid_fetch_constants=false') 'Default texture setting incorrect'
Assert ($rov -contains '--gpu_allow_invalid_fetch_constants=true') 'ROV texture compatibility not forwarded'
$cache=Arg $rov '--cache_root'
Assert ($cache -eq (Arg $repeat '--cache_root')) 'Repeated launch selected a different cache'
Assert ($cache -ne (Arg $default '--cache_root')) 'Rendering modes share a cache'
Assert ($cache -ne (Arg $scaled '--cache_root')) 'Scales share a cache'
Assert ((Arg $rov '--metadata_root') -ne (Arg $default '--metadata_root')) 'Rendering metadata not separated'
Assert ((Arg $rov '--user_data_root') -eq (Arg $default '--user_data_root')) 'Save location changed between modes'
New-Item -ItemType Directory -Path $cache -Force | Out-Null
$sentinel=Join-Path $cache 'preserve-cache.bin'
Set-Content -LiteralPath $sentinel -Value 'Keep existing cache'
$before=(Get-FileHash $sentinel).Hash
function Start-Process {param($FilePath,$ArgumentList,$WorkingDirectory,[switch]$PassThru,[switch]$Wait);[pscustomobject]@{ExitCode=0}}
try {& $runner -Configuration Release -GameDataRoot $GameDataRoot -RenderingPath ROV | Out-Null} finally {Remove-Item Function:Start-Process}
Assert ((Get-FileHash $sentinel).Hash -eq $before) 'Launch changed existing cache content'
$record=Get-ChildItem (Join-Path $fixture 'reports') -Filter '*.settings.json' | Select-Object -First 1
$settings=Get-Content $record.FullName -Raw | ConvertFrom-Json
Assert ($settings.RenderingPath -eq 'ROV' -and $settings.CacheFilesBefore -eq 1) 'Diagnostic settings missing cache reuse evidence'
Write-Output 'PASS: Default/ROV flags, persistent isolated caches, scale separation, unchanged save root, cache preservation and diagnostic settings. Process startup mocked; no game launched.'
Write-Output "Test artifacts: $fixture"
