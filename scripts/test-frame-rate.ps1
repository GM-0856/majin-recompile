param([string]$GameDataRoot)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'game-data.ps1')
if(!$GameDataRoot){$GameDataRoot=Get-MajinGameDataPath}
$fixture=Join-Path $env:TEMP ('Majin frame mode '+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts'),(Join-Path $fixture 'prototype/out/build/win-amd64-release') -Force | Out-Null
foreach($name in @('run.ps1','game-data.ps1','frame-rate.ps1')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $fixture 'scripts')}
Set-Content -LiteralPath (Join-Path $fixture 'prototype/out/build/win-amd64-release/majin.exe') -Value 'Synthetic marker majin_60fps; never executed.'
$runner=Join-Path $fixture 'scripts/run.ps1'
function Check($condition,$message){if(!$condition){throw $message}}
function Value($list,$key){$index=[Array]::IndexOf($list,$key);Check ($index -ge 0) ('Missing '+$key);$list[$index+1]}
$original=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -Preview)
$fast=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -FrameRateMode 60 -Preview)
$off=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -FrameRateMode 60 -VSync $false -Preview)
$rov=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -FrameRateMode 60 -RenderingPath ROV -Preview)
Check ($original -contains '--majin_60fps=false') 'Original must explicitly disable a stale runtime-config override'
Check ($fast -contains '--majin_60fps=true') '60 FPS opt-in not forwarded'
Check ($fast -contains '--vsync=true' -and $off -contains '--vsync=false') 'VSync must remain an independent user choice'
Check ((Value $original '--cache_root') -eq (Value $fast '--cache_root')) 'Timing mode must reuse the same shader cache'
Check ((Value $original '--user_data_root') -eq (Value $fast '--user_data_root')) 'Timing mode changed the save directory'
Check ((Value $rov '--cache_root') -ne (Value $fast '--cache_root')) 'ROV must retain its own cache'
Check ($rov -contains '--render_target_path_d3d12=rov') '60 FPS changed the chosen rendering path'
$rejected=$false
try{& $runner -Configuration Release -GameDataRoot $GameDataRoot -FrameRateMode 120 -Preview | Out-Null}catch{$rejected=$true}
Check $rejected 'Unsupported frame-mode input accepted'
$native=Join-Path $fixture 'prototype/out/build/win-amd64-release/majin.exe'
Set-Content -LiteralPath $native -Value 'Legacy synthetic placeholder; never executed.'
$legacy=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -Preview)
Check (!($legacy -contains '--majin_60fps=false')) 'Legacy executable received an unsupported argument'
$rejected=$false
try{& $runner -Configuration Release -GameDataRoot $GameDataRoot -FrameRateMode 60 -Preview | Out-Null}catch{$rejected=$true}
Check $rejected 'Legacy executable accepted an unsupported 60 FPS selection'
[IO.File]::WriteAllText($native,('x'*65531)+'majin_60fps',[Text.Encoding]::ASCII)
$boundary=@(& $runner -Configuration Release -GameDataRoot $GameDataRoot -FrameRateMode 60 -Preview)
Check ($boundary -contains '--majin_60fps=true') 'Capability marker crossing a read boundary was missed'
Write-Output 'PASS: frame opt-in, Original reset, VSync independence, cache reuse, save continuity, ROV isolation and invalid-mode rejection. Process launch not executed.'
