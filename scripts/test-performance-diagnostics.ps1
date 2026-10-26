param([string]$TestRoot)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$TestRoot){$TestRoot=Join-Path $root ('private/diagnostic-tests/'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6))}
New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
. (Join-Path $PSScriptRoot 'diagnostics-common.ps1')
Initialize-MajinPerformanceTools
$script:checks=0
function Check([bool]$Condition,[string]$Message){$script:checks++;if(!$Condition){throw $Message}}
function Near([double]$Actual,[double]$Expected,[string]$Message){Check ([math]::Abs($Actual-$Expected) -lt 0.000001) $Message}
function Analyze([string]$Name,[string[]]$Rows){
    $path=Join-Path $TestRoot ($Name+'.csv')
    [IO.File]::WriteAllLines($path,@('frame_time_us,fps')+$Rows)
    return [Majin.Diagnostics.Frames]::Analyze($path,$path+'.series.csv')
}
$steady=Analyze 'steady' (@('0,0')+@(1..100 | ForEach-Object {'16667,999'}))
Check ($steady.ValidIntervals -eq 100 -and $steady.ZeroIntervals -eq 1) 'Initial zero interval must be excluded'
Near $steady.AverageFPS (1000000/16667) 'FPS must be derived from interval duration, not the integer CSV FPS field'
Near $steady.P99FrameMs 16.667 'Steady percentile'
$hitch=Analyze 'hitch' (@(1..100 | ForEach-Object {'16667,999'})+@('500000,999'))
Near $hitch.AverageFPS (101000000/2166700) 'FPS must be duration weighted'
Near $hitch.MaximumFrameMs 500 'Do not discard a real hitch'
Check ($hitch.Over50Ms -eq 1 -and $hitch.Over100Ms -eq 1) 'Hitch counts'
$rank=Analyze 'percentile' @(1..100 | ForEach-Object {"$_,0"})
Near $rank.P50FrameMs .050 'Nearest rank P50'
Near $rank.P95FrameMs .095 'Nearest rank P95'
Near $rank.P99FrameMs .099 'Nearest rank P99'
$bad=Analyze 'invalid' @('0,0','-1,0','not-a-number,0','999999999999999999999999,0','16667','16667,60','86400000001,0')
Check ($bad.ValidIntervals -eq 1 -and $bad.InvalidRows -eq 5 -and $bad.ZeroIntervals -eq 1) 'Reject invalid, negative, oversized and incomplete records'
$empty=Analyze 'no-samples' @('0,0')
Check ($empty.ValidIntervals -eq 0 -and $empty.AverageFPS -eq 0) 'Empty capture cannot report fictitious FPS'
$failed=$false
try{[void][Majin.Diagnostics.Frames]::ReadBoundedLine((New-Object IO.StringReader(('x'*4097))))}catch{$failed=$true}
Check $failed 'Bound diagnostic line length'
$long=Analyze 'long-stall' @('5000000,0','16667,60')
$windows=@(Import-Csv (Join-Path $TestRoot 'long-stall.csv.series.csv'))
Check ($windows.Count -eq 2 -and [double]$windows[0].window_ms -eq 5000) 'Do not compress a five-second stall into one second'
Near ([double]$windows[0].average_fps) .2 'Long stall window FPS'
Check (($windows | Measure-Object -Property intervals -Sum).Sum -eq 2) 'Every interval must remain in the time series'

$package=Join-Path $TestRoot 'fixture'
$scripts=Join-Path $package 'scripts';$reports=Join-Path $package 'reports'
New-Item -ItemType Directory -Path $scripts,$reports -Force | Out-Null
foreach($name in @('collect-diagnostics.ps1','collect-diagnostics-assisted.ps1','diagnostics-common.ps1','performance-metrics.cs')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $scripts $name)}
[IO.File]::WriteAllText((Join-Path $package 'VERSION'),'test-only')
[IO.File]::WriteAllText((Join-Path $package 'Majin FK Launcher.exe'),'synthetic marker; never executable')
$log=Join-Path $reports 'runtime-20000101-000000.log'
$lines=@('[2000-01-01 00:00:00.000] [info] [gpu] [t1] DXGI adapter: Test GPU (vendor 0x1234, device 0x0001)',
 '[2000-01-01 00:00:01.000] [warning] [gpu] [t1] Texture fetch constant has "invalid" type!',
 '[2000-01-01 00:00:01.001] [warning] [gpu] [t1] [Majin texture-warning summary] occurrences=12345; suppressed=12300; texture validation unchanged.',
 '[2000-01-01 00:00:01.002] [warning] [apu] [t1] [Majin XMA recovery v2] test',
 ('[2000-01-01 00:00:01.003] [info] [core] [t1] '+$package+'\private\example'),
 ('[2000-01-01 00:00:01.004] [info] [core] [t1] C:/'+'Users/'+'PrivateTestAccount/data'),
 '[2000-01-01 00:00:01.005] [info] [core] [t1] \\PrivateTestMachine\Share\data')
[IO.File]::WriteAllLines($log,$lines)
@{Configuration='Release';GameDataRoot='F:\DoNotExport\game';CacheRoot='F:\DoNotExport\cache';InputMode='KeyboardMouse';RecordPerformance=$true;IncludeHardware=$false} | ConvertTo-Json | Set-Content -LiteralPath ($log+'.settings.json')
[IO.File]::WriteAllLines(($log+'.performance.csv'),@('frame_time_us,fps')+@(1..100 | ForEach-Object {'16667,60'}))
$report=Write-MajinPerformanceSummary $log
Check ($report.Warnings.TextureOccurrences -eq 12345 -and $report.Warnings.TextureSuppressed -eq 12300) 'Retain bounded texture occurrence counts'
Check ($report.Warnings.XmaRecoveryEvents -eq 1) 'Retain XMA recovery count'

# Query mocks deliberately contain fields that must never be serialized.
function Get-CimInstance {
    param([string]$ClassName,[string[]]$Property,[string]$ErrorAction)
    return [pscustomobject]@{Name='Test Model';Caption='Test OS';Version='1';BuildNumber='1';TotalVisibleMemorySize=8388608;NumberOfCores=4;NumberOfLogicalProcessors=8;DriverVersion='1.2.3';CSName='PrivateTestMachine';UserName='PrivateTestAccount';SerialNumber='DO-NOT-EXPORT-SERIAL';UUID='DO-NOT-EXPORT-UUID';MACAddress='DO-NOT-EXPORT-MAC'}
}
function Get-WinEvent {
    param($FilterHashtable,[int]$MaxEvents,[string]$ErrorAction)
    $event=[pscustomobject]@{TimeCreated=[datetime]'2000-01-01';Id=1000;ProviderName='Application Error';Message='majin PrivateTestAccount PrivateTestMachine'}
    $event | Add-Member -MemberType ScriptMethod -Name ToXml -Value {return '<Event><System><Computer>PrivateTestMachine</Computer><Security UserID="PrivateTestSID"/></System><EventData><Data Name="AppName">C:'+'\Users\'+'PrivateTestAccount\majin.exe</Data><Data Name="ExceptionCode">0xc0000005</Data><Data Name="Other">DO-NOT-EXPORT-SERIAL</Data></EventData></Event>'}
    return $event
}
$hardware=Get-MajinHardwareSummary
$serialized=$hardware | ConvertTo-Json -Depth 6
Check ($serialized -notmatch 'PrivateTest|DO-NOT-EXPORT') 'Hardware allowlist must exclude identifiers'
Check ($hardware.CPU[0].Cores -eq 4 -and $hardware.UsableRAMGiB -eq 8 -and $hardware.GPU[0].DriverVersion -eq '1.2.3') 'Retain useful anonymous hardware fields'
Check (!(Get-MajinDiagnosticConsent -Root $package)) 'Hardware must default to opt-out'
Check (Get-MajinDiagnosticConsent -Root $package -IncludeHardware) 'Explicit hardware consent'
Check (!(Get-MajinDiagnosticConsent -Root $package -IncludeHardware -SkipHardware)) 'SkipHardware must override inclusion'
$hardware | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ($log+'.hardware.json')
& (Join-Path $scripts 'collect-diagnostics.ps1') -SkipHardware | Out-Null
$zip=Get-ChildItem -LiteralPath $reports -Filter '*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$unpacked=Join-Path $TestRoot 'regular-no-hardware';Expand-Archive -LiteralPath $zip.FullName -DestinationPath $unpacked
$files=@(Get-ChildItem -LiteralPath $unpacked -Recurse -File)
Check (@($files | Where-Object Name -Like '*.performance.csv').Count -eq 1) 'Frame CSV must be collected'
Check (@($files | Where-Object Name -Like '*.performance-summary.json').Count -eq 1) 'Frame/warning summary must be collected'
Check (@($files | Where-Object Name -Like '*.hardware.json').Count -eq 0) 'SkipHardware must omit saved hardware artifacts'
foreach($file in $files){Check ((Get-Content -LiteralPath $file.FullName -Raw) -notmatch 'PrivateTest|DoNotExport') 'No personal fixture identifiers/paths in exported diagnostic text'}
& (Join-Path $scripts 'collect-diagnostics.ps1') -IncludeHardware | Out-Null
$zip=Get-ChildItem -LiteralPath $reports -Filter '*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$withHardware=Join-Path $TestRoot 'regular-opt-in';Expand-Archive -LiteralPath $zip.FullName -DestinationPath $withHardware
$info=Get-ChildItem -LiteralPath $withHardware -Filter 'DIAGNOSTIC-INFO.json' -Recurse | Get-Content -Raw | ConvertFrom-Json
Check ($info.HardwareOptIn -and $info.Hardware.CPU[0].Cores -eq 4) 'Include hardware only after consent'
foreach($file in Get-ChildItem -LiteralPath $withHardware -Recurse -File){Check ((Get-Content -LiteralPath $file.FullName -Raw) -notmatch 'PrivateTest|DoNotExport|DO-NOT-EXPORT') 'Opt-in archive must still exclude identifiers'}
& (Join-Path $scripts 'collect-diagnostics-assisted.ps1') -RootPaths @($package) -OutputRoot (Join-Path $TestRoot 'assisted') -SkipHardware | Out-Null
$zip=Get-ChildItem -LiteralPath (Join-Path $TestRoot 'assisted') -Filter '*.zip' | Select-Object -First 1
$assisted=Join-Path $TestRoot 'assisted-unpacked';Expand-Archive -LiteralPath $zip.FullName -DestinationPath $assisted
foreach($file in Get-ChildItem -LiteralPath $assisted -Recurse -File){Check ((Get-Content -LiteralPath $file.FullName -Raw) -notmatch 'PrivateTest|DoNotExport|DO-NOT-EXPORT|UserID|<Computer>') 'Assisted export must strip Windows-event identifiers too'}
$events=Get-ChildItem -LiteralPath $assisted -Filter 'FALHAS-WINDOWS.json' -Recurse | Get-Content -Raw | ConvertFrom-Json
Check ($events.Data.AppName -eq 'majin.exe' -and $events.Data.ExceptionCode -eq '0xc0000005') 'Preserve useful Windows failure fields'
# Bounded tail exports must preserve the CSV header and disclose truncation.
$large=Join-Path $TestRoot 'runtime-20000101-000001.log.performance.csv'
[IO.File]::WriteAllText($large,"frame_time_us,fps`n"+("16667,60`n"*1000000))
$tailDestination=Join-Path $TestRoot 'tail-export';New-Item -ItemType Directory -Path $tailDestination | Out-Null
$copied=0L
$entry=Copy-MajinDiagnosticArtifact -File (Get-Item -LiteralPath $large) -Destination $tailDestination -LocalRoots @($TestRoot) -AllowHardware $false -CopiedBytes ([ref]$copied)
Check ($entry.TailOnly -and $entry.ExportedBytes -le (8MB+4096)) 'Bound and label raw CSV tail'
$tailPath=Join-Path $tailDestination ([IO.Path]::GetFileName($large))
$tailReader=New-Object IO.StreamReader($tailPath)
try{Check ($tailReader.ReadLine() -eq 'frame_time_us,fps') 'Retain header after truncation';Check ($tailReader.ReadLine() -eq '16667,60') 'Discard only the cut partial CSV row'}finally{$tailReader.Dispose()}
$tailSummary=[Majin.Diagnostics.Frames]::Analyze($tailPath,$tailPath+'.series.csv')
Check ($tailSummary.ValidIntervals -gt 0 -and $tailSummary.InvalidRows -eq 0) 'Truncated raw CSV must remain parseable'
$badHeader=Join-Path $TestRoot 'unknown-schema.csv';[IO.File]::WriteAllText($badHeader,"unexpected`n123`n")
$failed=$false;try{[void][Majin.Diagnostics.Frames]::Analyze($badHeader,$badHeader+'.series.csv')}catch{$failed=$true}
Check $failed 'Reject an unknown CSV schema'
$result=@{Checks=$script:checks;Result='passed';Scope='Synthetic frame calculations, collector integration, hardware opt-in and Windows-event privacy'}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $TestRoot 'TEST-RESULTS.json')
Write-Output ('PASS: '+$script:checks+' diagnostic/performance/privacy checks.')
