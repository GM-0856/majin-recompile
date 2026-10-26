param([string[]]$RootPaths,[string]$OutputRoot,[switch]$IncludeHardware,[switch]$SkipHardware,[switch]$SkipWindowsEvents,[switch]$OpenResult)
$ErrorActionPreference='Stop'
$packageRoot=Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'diagnostics-common.ps1')
$allowHardware=Get-MajinDiagnosticConsent -Root $packageRoot -IncludeHardware:$IncludeHardware -SkipHardware:$SkipHardware
if(!$OutputRoot){$OutputRoot=Join-Path $packageRoot 'reports'}
if(!$RootPaths){
 $locations=@([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('MyDocuments'),$PSScriptRoot) | Select-Object -Unique
 $RootPaths=@($packageRoot)+@(foreach($location in $locations){if(Test-Path -LiteralPath $location){Get-ChildItem -LiteralPath $location -Directory -ErrorAction SilentlyContinue | Where-Object Name -Like '*Majin*' | ForEach-Object {$_.FullName}}})
}
$name='Majin-Diagnostico-Assistido-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,6)
$destination=Join-Path $OutputRoot $name
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$notes=New-Object 'System.Collections.Generic.List[string]'
$found=New-Object 'System.Collections.Generic.List[string]'
$packages=New-Object 'System.Collections.Generic.List[string]'
$visited=@{};$queue=New-Object System.Collections.Queue
foreach($path in $RootPaths){if(Test-Path -LiteralPath $path -PathType Container){$queue.Enqueue(@{Path=[IO.Path]::GetFullPath($path);Depth=0})}}
function Protect-Text([string]$text){return (Protect-MajinDiagnosticText -Text $text -LocalRoots (@($packageRoot)+@($RootPaths)))}
while($queue.Count -gt 0 -and $visited.Count -lt 3000){
 $current=$queue.Dequeue();$path=$current.Path
 if($visited.ContainsKey($path)){continue};$visited[$path]=$true
 try {
  if((Test-Path -LiteralPath (Join-Path $path 'Start Majin.cmd')) -or (Test-Path -LiteralPath (Join-Path $path 'Majin FK Launcher.exe'))){$packages.Add($path)}
  if((Split-Path $path -Leaf) -eq 'reports'){
   foreach($file in Get-ChildItem -LiteralPath $path -File -ErrorAction Stop){
    if($file.Name -match '^runtime-\d{8}-\d{6}(?:\.\d+)?\.log(?:\.settings\.json|\.hardware\.json|\.performance\.csv|\.performance-1s\.csv|\.performance-summary\.json)?$'){$found.Add($file.FullName)}
   }
   continue
  }
  if($current.Depth -ge 9){continue}
  foreach($child in Get-ChildItem -LiteralPath $path -Directory -ErrorAction Stop){
   if(($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $child.Name -match '^(\.git|private|game-data|finalizedXBox360|tools|out|node_modules|02-Dados-pessoais|04-Resultados|06-Fontes|07-ISO|Diagnosticos-Majin)$'){continue}
   $queue.Enqueue(@{Path=$child.FullName;Depth=$current.Depth+1})
  }
 } catch {$notes.Add('Folder query unavailable: '+(Protect-Text $path))}
}
$sessions=@($found | ForEach-Object {Get-Item -LiteralPath $_} | Sort-Object LastWriteTime -Descending | Select-Object -First 30)
$copied=0L;$index=@();$i=0
foreach($file in $sessions){
 $i++;$folder=Join-Path $destination ('Session-'+$i.ToString('00'));New-Item -ItemType Directory -Path $folder | Out-Null
 $entry=Copy-MajinDiagnosticArtifact -File $file -Destination $folder -LocalRoots (@($packageRoot)+@($RootPaths)) -AllowHardware $allowHardware -CopiedBytes ([ref]$copied)
 if($entry){$index+=@{File=$entry.File;TailOnly=$entry.TailOnly;OriginalBytes=$entry.OriginalBytes;ExportedBytes=$entry.ExportedBytes}}
 else{$notes.Add('Excluded or size-limited artifact: '+$file.Name)}
}
$logCount=@($sessions | Where-Object Name -Match '\.log$').Count
$events=@()
if(!$SkipWindowsEvents){
 try {
  $records=@(Get-WinEvent -FilterHashtable @{LogName='Application';Id=@(1000,1001,1026);StartTime=(Get-Date).AddDays(-10)} -MaxEvents 300 -ErrorAction Stop)
  foreach($record in $records){
   if($record.Message -match '(?i)majin|rexruntime|rexgpu'){
    # Export a small event-data allowlist, never MachineName, SID, report IDs or full XML/message.
    $data=[ordered]@{}
    $xml=[xml]$record.ToXml()
    foreach($item in $xml.Event.EventData.Data){
     if([string]$item.Name -in @('AppName','AppVersion','ModuleName','ModuleVersion','ExceptionCode','FaultingOffset','ExceptionOffset')){
      $value=[string]$item.InnerText
      if([string]$item.Name -in @('AppName','ModuleName')){$value=[IO.Path]::GetFileName($value)}
      if($value.Length -le 256){$data[[string]$item.Name]=Protect-Text $value}
     }
    }
    $events+=@{Time=[string]$record.TimeCreated;Id=$record.Id;Provider=$record.ProviderName;Data=$data}
   }
  }
 } catch {$notes.Add('Windows failure events unavailable or no matching records: '+$_.Exception.GetType().Name)}
}
$binaries=@()
foreach($package in $packages | Select-Object -Unique){
 foreach($configuration in @('release','debug')){
  $build=Join-Path $package ('prototype/out/build/win-amd64-'+$configuration)
  if(Test-Path -LiteralPath $build){foreach($binary in Get-ChildItem -LiteralPath $build -File | Where-Object Name -Match '^(majin\.exe|rexruntime[d]?\.dll|rexgpu-xenos[d]?\.dll)$'){
   $binaries+=@{Package=Protect-Text $package;Name=$binary.Name;SHA256=(Get-FileHash -LiteralPath $binary.FullName -Algorithm SHA256).Hash}
  }}
 }
}
$hardware=$null
if($allowHardware){try{$hardware=Get-MajinHardwareSummary}catch{$notes.Add('Hardware query unavailable.')}}
if(!$logCount){$notes.Add('NO GAME LOGS FOUND. Run the game from the notebook copy that fails, then run this collector again.')}
if(!$logCount -and !$events.Count){$notes.Add('No game logs or relevant Windows events. This archive cannot identify the crash. See the instructions in this tool.')}
@{CollectorVersion=3;HardwareOptIn=$allowHardware;ActiveGPUAlreadyInRuntimeLog=$true;Collected=(Get-Date -Format o);Computer=$hardware;GameLogFileCount=$logCount;SessionArtifactCount=$sessions.Count;WindowsFailureEventCount=$events.Count;CanInvestigateCrash=($logCount -gt 0 -or $events.Count -gt 0);SearchedRoots=@($RootPaths | ForEach-Object {Protect-Text $_});Files=$index;Binaries=$binaries;Notes=@($notes);OriginalGameDataIncluded=$false;AutomaticUpload=$false} | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $destination 'RESUMO.json') -Encoding UTF8
$events | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $destination 'FALHAS-WINDOWS.json') -Encoding UTF8
$zip=$destination+'.zip'
Compress-Archive -LiteralPath $destination -DestinationPath $zip
Write-Output ('Logs do jogo encontrados: '+$logCount)
Write-Output ('Registros de falha do Windows: '+$events.Count)
Write-Output ('ZIP: '+$zip)
if(!$logCount -and !$events.Count){Write-Warning 'Nao foram encontrados registros da falha. Abra a copia do jogo no notebook, reproduza o erro e execute este coletor novamente.'}
if($OpenResult){Start-Process explorer.exe -ArgumentList ('/select,"'+$zip+'"') -WindowStyle Hidden}
