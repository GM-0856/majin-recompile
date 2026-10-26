# SPDX-License-Identifier: GPL-3.0-only
function Protect-MajinDiagnosticText([string]$Text,[string[]]$LocalRoots=@()) {
    foreach($path in @($LocalRoots | Where-Object {$_} | Sort-Object Length -Descending)+@($env:USERPROFILE)) {
        if($path){$Text=$Text.Replace($path.Replace('\','\\'),'<LOCAL>').Replace($path,'<LOCAL>').Replace($path.Replace('\','/'),'<LOCAL>')}
    }
    $Text=[regex]::Replace($Text,'(?i)[a-z]:(?:\\+|/)Users(?:\\+|/)[^\\/"\r\n]+','<USERPROFILE>')
    # Network share names may identify a machine or account; do not export them.
    $Text=[regex]::Replace($Text,'(?i)(?<![a-z0-9:])\\\\[^\\\s"<>]+\\[^\s"<>]*','<NETWORK-PATH>')
    return $Text
}

function Get-MajinHardwareSummary {
    # Explicit property allowlist. Never serialize whole CIM/WMI objects.
    $os=Get-CimInstance Win32_OperatingSystem -Property Caption,Version,BuildNumber,TotalVisibleMemorySize -ErrorAction Stop
    return [ordered]@{
        OS=[string]$os.Caption; OSVersion=[string]$os.Version; Build=[string]$os.BuildNumber
        UsableRAMGiB=[math]::Round([double]$os.TotalVisibleMemorySize/1MB,2)
        CPU=@(Get-CimInstance Win32_Processor -Property Name,NumberOfCores,NumberOfLogicalProcessors -ErrorAction Stop | ForEach-Object {
            @{Name=[string]$_.Name;Cores=[int]$_.NumberOfCores;LogicalProcessors=[int]$_.NumberOfLogicalProcessors}
        })
        GPU=@(Get-CimInstance Win32_VideoController -Property Name,DriverVersion -ErrorAction Stop | ForEach-Object {
            @{Name=[string]$_.Name;DriverVersion=[string]$_.DriverVersion}
        })
        Excludes=@('user and computer names','serial numbers','hardware UUIDs','SIDs','IP and MAC addresses','installed applications')
    }
}

function Initialize-MajinPerformanceTools {
    if(-not ('Majin.Diagnostics.Frames' -as [type])) {Add-Type -Path (Join-Path $PSScriptRoot 'performance-metrics.cs')}
}

function Get-MajinWarningSummary([string]$LogPath) {
    $summary=[ordered]@{WarningRecords=0L;ErrorRecords=0L;CriticalRecords=0L;FatalRecords=0L;TextureSamples=0L;TextureOccurrences=$null;TextureSuppressed=$null;XmaRecoveryEvents=0L;UnscaledResolveWarning=$false;ActiveGPU=$null;CaptureLimitReached=$false;ScanTruncated=$false}
    if(!(Test-Path -LiteralPath $LogPath)){return $summary}
    Initialize-MajinPerformanceTools
    $reader=New-Object IO.StreamReader($LogPath)
    $lineCount=0;$chars=0L
    try {
        while($null -ne ($line=[Majin.Diagnostics.Frames]::ReadBoundedLine($reader))) {
            $chars+=$line.Length
            if(++$lineCount -gt 500000 -or $chars -gt 32MB){$summary.ScanTruncated=$true;break}
            if($line -match '\] \[(warning|error|critical|fatal)\] '){
                switch($Matches[1]) {warning{$summary.WarningRecords++} error{$summary.ErrorRecords++} critical{$summary.CriticalRecords++} fatal{$summary.FatalRecords++}}
            }
            if($line.Contains('Texture fetch constant') -and $line.Contains('invalid')){$summary.TextureSamples++}
            if($line -match '\[Majin texture-warning summary\] occurrences=(\d+); suppressed=(\d+)'){
                $summary.TextureOccurrences=[math]::Max([long]$summary.TextureOccurrences,[long]$Matches[1]);$summary.TextureSuppressed=[math]::Max([long]$summary.TextureSuppressed,[long]$Matches[2])
            }
            if($line.Contains('[Majin XMA recovery')){$summary.XmaRecoveryEvents++}
            if($line.Contains('Frame capture reached 2000000 rows and stopped')){$summary.CaptureLimitReached=$true}
            if($line.Contains('swap source is unscaled')){$summary.UnscaledResolveWarning=$true}
            if($line -match 'DXGI adapter: (.+) \(vendor '){$summary.ActiveGPU=$Matches[1]}
        }
    } catch {$summary.ScanTruncated=$true} finally {$reader.Dispose()}
    return $summary
}

function Write-MajinPerformanceSummary([string]$LogPath) {
    Initialize-MajinPerformanceTools
    $csv=$LogPath+'.performance.csv'
    $frames=$null
    $notes=New-Object 'System.Collections.Generic.List[string]'
    if(Test-Path -LiteralPath $csv){
        try {$frames=[Majin.Diagnostics.Frames]::Analyze($csv,$LogPath+'.performance-1s.csv')}
        catch {$notes.Add('Frame analysis unavailable: '+$_.Exception.GetType().Name)}
    } else {$notes.Add('No frame CSV available; an older game binary or disabled recording may be in use.')}
    $warnings=Get-MajinWarningSummary $LogPath
    $result=[ordered]@{SchemaVersion=1;Frames=$frames;Warnings=$warnings;Notes=@($notes);AutomaticUpload=$false}
    $result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath ($LogPath+'.performance-summary.json') -Encoding UTF8
    if($frames -and $frames.ValidIntervals -gt 0){
        $culture=[Globalization.CultureInfo]::InvariantCulture
        $message='[Majin performance summary] source=guest_gpu_swap_interval intervals={0} average_fps={1} mean_ms={2} p95_ms={3} p99_ms={4} max_ms={5}; includes loading/pauses; not GPU execution time.' -f $frames.ValidIntervals,$frames.AverageFPS.ToString('F3',$culture),$frames.MeanFrameMs.ToString('F3',$culture),$frames.P95FrameMs.ToString('F3',$culture),$frames.P99FrameMs.ToString('F3',$culture),$frames.MaximumFrameMs.ToString('F3',$culture)
        Add-Content -LiteralPath $LogPath -Value $message -Encoding UTF8
    }
    return $result
}

function Get-MajinDiagnosticConsent([string]$Root,[switch]$IncludeHardware,[switch]$SkipHardware) {
    if($SkipHardware){return $false}
    if($IncludeHardware){return $true}
    $settings=Join-Path $Root 'private/launcher.json'
    if(Test-Path -LiteralPath $settings){try {
        $saved=Get-Content -LiteralPath $settings -Raw | ConvertFrom-Json
        return ($saved.IncludeHardware -is [bool] -and $saved.IncludeHardware)
    }catch{}}
    return $false
}

function Copy-MajinDiagnosticArtifact([IO.FileInfo]$File,[string]$Destination,[string[]]$LocalRoots,[bool]$AllowHardware,[ref]$CopiedBytes) {
    if($File.Name.EndsWith('.hardware.json') -and !$AllowHardware){return $false}
    $max=if($File.Name.EndsWith('.performance.csv')){8MB}else{2MB}
    if($CopiedBytes.Value+[math]::Min($File.Length,$max)+4096 -gt 25MB){return $false}
    $tail=$File.Length -gt $max
    if($tail -and $File.Extension -eq '.json'){return $false}
    $stream=[IO.File]::Open($File.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::ReadWrite)
    $reader=New-Object IO.StreamReader($stream)
    try {
        $header=$null
        if($tail){
            if($File.Extension -eq '.csv'){$header=$reader.ReadLine()}
            $reader.DiscardBufferedData();[void]$stream.Seek([math]::Max(0,$stream.Length-$max),[IO.SeekOrigin]::Begin)
            [void]$reader.ReadLine()
        }
        $text=$reader.ReadToEnd()
        if($header){$text=$header+"`n"+$text}
    }finally{$reader.Dispose()}
    if($File.Name.EndsWith('.log.settings.json')){
        # Export only diagnostic settings, never arbitrary game/cache paths.
        $raw=$text | ConvertFrom-Json;$safe=[ordered]@{}
        foreach($key in @('FrameRateMode','Configuration','RenderingPath','RenderScale','CacheFilesBefore','WindowSize','Fullscreen','VSync','PostEffect','InputMode','MouseSensitivity','RecordPerformance','IncludeHardware')){
            if($raw.PSObject.Properties.Name -contains $key){$safe[$key]=$raw.$key}
        }
        $text=$safe | ConvertTo-Json -Depth 4
    }
    $text=Protect-MajinDiagnosticText $text $LocalRoots
    $bytes=[Text.Encoding]::UTF8.GetByteCount($text)
    if($CopiedBytes.Value+$bytes -gt 25MB){return $false}
    [IO.File]::WriteAllText((Join-Path $Destination $File.Name),$text)
    $CopiedBytes.Value+=$bytes
    return [pscustomobject]@{File=$File.Name;TailOnly=$tail;OriginalBytes=$File.Length;ExportedBytes=$bytes}
}
