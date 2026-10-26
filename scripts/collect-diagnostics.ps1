param([ValidateRange(1,5)][int]$SessionCount=3,[switch]$IncludeHardware,[switch]$SkipHardware)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'diagnostics-common.ps1')
$reports=Join-Path $root 'reports'
$name='Majin-Diagnostics-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,6)
$destination=Join-Path $reports $name
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$notes=New-Object 'System.Collections.Generic.List[string]'
$copiedBytes=0L;$index=@()
$allowHardware=Get-MajinDiagnosticConsent -Root $root -IncludeHardware:$IncludeHardware -SkipHardware:$SkipHardware
$sessions=@(Get-ChildItem -LiteralPath $reports -File -Filter '*.log.settings.json' | Where-Object Name -Match '^runtime-\d{8}-\d{6}\.log\.settings\.json$' | Sort-Object LastWriteTime -Descending | Select-Object -First $SessionCount)
foreach($session in $sessions){
    $stem=$session.Name.Replace('.log.settings.json','')
    $selected=@(Get-ChildItem -LiteralPath $reports -File -Filter ($stem+'*') | Where-Object Name -Match ('^'+[regex]::Escape($stem)+'(?:\.\d+)?\.log(?:\.settings\.json|\.hardware\.json|\.performance\.csv|\.performance-1s\.csv|\.performance-summary\.json)?$') | Sort-Object Name | Select-Object -First 26)
    foreach($file in $selected){
        $entry=Copy-MajinDiagnosticArtifact -File $file -Destination $destination -LocalRoots @($root) -AllowHardware $allowHardware -CopiedBytes ([ref]$copiedBytes)
        if($entry){$index+=$entry}else{$notes.Add('Excluded or size-limited artifact: '+$file.Name)}
    }
}
$binaries=@()
foreach($configuration in @('release','debug')){
    $build=Join-Path $root ('prototype/out/build/win-amd64-'+$configuration)
    if(Test-Path -LiteralPath $build){foreach($binary in Get-ChildItem -LiteralPath $build -File | Where-Object Name -Match '^(majin\.exe|rexruntime[d]?\.dll|rexgpu-xenos[d]?\.dll)$'){
        $binaries+=@{Name=$binary.Name;Configuration=$configuration;SHA256=(Get-FileHash -LiteralPath $binary.FullName -Algorithm SHA256).Hash}
    }}
}
$hardware=$null
if($allowHardware){try{$hardware=Get-MajinHardwareSummary}catch{$notes.Add('Hardware query unavailable: '+$_.Exception.GetType().Name)}}
$version=if(Test-Path -LiteralPath (Join-Path $root 'VERSION')){(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()}else{'unversioned'}
@{CollectorVersion=3;Version=$version;Collected=(Get-Date -Format o);SessionCount=$sessions.Count;HardwareOptIn=$allowHardware;Hardware=$hardware;Binaries=$binaries;Files=$index;Notes=@($notes);Excludes=@('game data','ISO','saves','shader-cache contents','user/computer names','serial numbers','network identifiers');ActiveGPUAlreadyInRuntimeLog=$true;AutomaticUpload=$false} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $destination 'DIAGNOSTIC-INFO.json') -Encoding UTF8
$archive=$destination+'.zip'
Compress-Archive -LiteralPath $destination -DestinationPath $archive -CompressionLevel Optimal
Write-Output "Diagnostics: $archive"
Write-Output 'Includes local frame metrics when available; truncated files are marked in the inventory.'
Write-Output ('Optional CPU/RAM/GPU details included: '+$allowHardware)
Write-Output 'Review the ZIP before sharing. Nothing was uploaded.'
