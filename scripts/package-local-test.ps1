param([string]$OutputParent, [ValidateSet('Debug','Release')][string]$Configuration='Debug', [string]$BinaryInputDirectory, [string]$BuildRecord)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$OutputParent){$OutputParent=Join-Path $root 'private/packages'}
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($version -notmatch '^\d+\.\d+\.\d+-alpha\.\d+$'){throw 'Invalid candidate version.'}
$name='Majin-Recompile-v'+$version+'-candidate-'+$Configuration.ToLower()+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')
$destination=Join-Path $OutputParent $name
if(Test-Path -LiteralPath $destination){throw 'Package destination already exists.'}
$files=@('LICENSE','COPYRIGHT.md','VERSION','RELEASE_NOTES.md','scripts/collect-diagnostics.ps1','scripts/diagnostics-common.ps1','scripts/performance-metrics.cs','PERFORMANCE_DIAGNOSTICS.md','scripts/launcher.ps1','scripts/run.ps1','scripts/game-data.ps1','scripts/disc-import.ps1','scripts/disc-image.cs','scripts/set-game-data.ps1','KEYBOARD_MOUSE.md','ALPHA_RELEASE.md','ISO_IMPORT.md','THIRD_PARTY.md','AI_USAGE.md','SOURCE_BUILD.md','LICENSES/ReXGlue.txt','prototype/out/build/win-amd64-debug/majin.exe','prototype/out/build/win-amd64-debug/rexruntimed.dll','prototype/out/build/win-amd64-debug/rexgpu-xenosd.dll','prototype/out/build/win-amd64-debug/TracyClientd.dll')
if($Configuration -eq 'Release'){
 $files=@($files | Where-Object {$_ -notlike '*TracyClientd.dll'} | ForEach-Object {$_.Replace('win-amd64-debug','win-amd64-release').Replace('rexruntimed.dll','rexruntime.dll').Replace('rexgpu-xenosd.dll','rexgpu-xenos.dll').Replace('TracyClientd.dll','TracyClient.dll')})
}
$expected=@{
 'majin.exe'='45F6FD55605992A61D3DEAF4AAEAB7A08667BE2D47A05EECA00804A4BA5025BF'
 'rexruntimed.dll'='F5B59D4FB6A10EB20AFBBFA7007F4FEEFB70E24D6AAE2253F0EA7AB7173C5978'
}
if($Configuration -eq 'Release'){
 $expected=@{
  'majin.exe'='D770B81035107294AB38EC73399939C39DD3E70E085A5A5E82C5F3FF0623D0A3'
  'rexruntime.dll'='030254596432595BAD0332D4AF9FCC24C337EDE4A729EE3875799F2B7FA6BB5A'
  'rexgpu-xenos.dll'='0C23CFA23FC4FA5638DC8A3DC0DE87B1041D97705D4677774083F1F350CD8D89'
 }
}
$buildEvidence=$null
if($BinaryInputDirectory -or $BuildRecord){
 if($Configuration -ne 'Release' -or !$BinaryInputDirectory -or !$BuildRecord){throw 'Clean candidate packaging requires Release, BinaryInputDirectory and BuildRecord.'}
 $buildEvidence=Get-Content -LiteralPath $BuildRecord -Raw | ConvertFrom-Json
 if($buildEvidence.Configuration -ne 'Release' -or $buildEvidence.Probe1080pEnabled -ne $false -or !$buildEvidence.GameSourceRevision -or !$buildEvidence.SdkRevision){throw 'Incomplete clean build evidence.'}
 $expected=@{}
 foreach($name in @('majin.exe','rexruntime.dll','rexgpu-xenos.dll')){
  $hash=$buildEvidence.Binaries.PSObject.Properties[$name].Value
  if($hash -notmatch '^[A-Fa-f0-9]{64}$'){throw "Missing clean binary fingerprint: $name"}
  $expected[$name]=$hash
 }
}
function Get-PackageInput([string]$relative){
 if($BinaryInputDirectory -and $relative.StartsWith('prototype/out/build/')){return (Join-Path $BinaryInputDirectory (Split-Path $relative -Leaf))}
 return (Join-Path $root $relative)
}
foreach($relative in $files){
 $source=Get-PackageInput $relative
 if(!(Test-Path -LiteralPath $source -PathType Leaf)){throw "Package input missing: $relative"}
 $leaf=Split-Path $source -Leaf
 if($expected.ContainsKey($leaf) -and (Get-FileHash -LiteralPath $source).Hash -ne $expected[$leaf]){throw "Stable binary fingerprint changed: $leaf. Review before packaging."}
}
# Explicit allowlist; never recursively copy the development tree.
New-Item -ItemType Directory -Path $destination -Force | Out-Null

foreach($relative in $files){
 $target=Join-Path $destination $relative
 New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
 Copy-Item -LiteralPath (Get-PackageInput $relative) -Destination $target
}
if($buildEvidence){Copy-Item -LiteralPath $BuildRecord -Destination (Join-Path $destination 'BUILD-EVIDENCE.json')}
# Repository-controlled notice inventory includes nested and embedded notices.
$noticeIndex=Get-Content -LiteralPath (Join-Path $root 'LICENSES/DEPENDENCY-NOTICES.json') -Raw | ConvertFrom-Json
$noticeFiles=@('LICENSES/DEPENDENCY-NOTICES.json')+@($noticeIndex.Notices | ForEach-Object {$_.NoticePath})
foreach($notice in $noticeIndex.Notices){
 $path=Join-Path $root $notice.NoticePath
 if((Get-FileHash -LiteralPath $path).Hash -ne $notice.SHA256){throw "Dependency notice changed: $($notice.NoticePath)"}
}
foreach($relative in $noticeFiles | Select-Object -Unique){
 $target=Join-Path $destination $relative
 New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
 Copy-Item -LiteralPath (Join-Path $root $relative) -Destination $target
}
@'
@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0scripts\launcher.ps1"
if errorlevel 1 pause
'@ | Set-Content -LiteralPath (Join-Path $destination 'Start Majin.cmd') -Encoding ASCII
@'
MAJIN RECOMPILE - LOCAL TEST PACKAGE

LOCAL DEVELOPMENT TEST ONLY. NOT A PUBLIC ALPHA RELEASE.
Uses the tested Debug build and requires Visual C++ DEBUG runtime DLLs on
the development PC. The ordinary VC++ Redistributable does not supply them.
Do not publish this candidate yet. Final gameplay and corresponding-source
distribution checks are still required. Project code uses GPL-3.0-only.

1. Extract the ZIP completely into a writable folder.
2. Double-click Start Majin.cmd.
3. Browse to your existing extracted game folder, or import your supported ISO.
   Browse avoids creating another game-data copy.
4. Select 720p or 1440p internal rendering and press Play.

No game data, DLC, personal saves, configuration, caches or original artwork
are included. Saves created here go into private/runtime/user INSIDE THIS
PACKAGE. Your development saves will not appear here automatically and will
not be overwritten. Logs go into reports.

Test a new game, save, quit with Esc/Yes, reopen and load that new save.
Check controller or keyboard/mouse. Internal 1080p is paused; 4K unvalidated.
The plain launcher background is intentional.
Rendering path: Default is automatic; ROV Compatibility may fix black images
but can reduce performance. Mode/build/scale caches are separate and reused.
First-run shader compilation may cause pauses. Re-test the same route.
Logs have adjacent .settings.json files identifying settings and cache paths.
Run Collect Diagnostics.cmd for a reviewed support ZIP. See RELEASE_NOTES.md for known issues.
This exact updated package still needs gameplay validation; see ALPHA_RELEASE.md.

PACKAGE-MANIFEST.json fingerprints included files. DEPENDENCIES.json lists
static imports only; dynamically loaded graphics components and clean-machine
requirements are not fully validated by this report.
'@ | Set-Content -LiteralPath (Join-Path $destination 'READ-ME-FIRST.txt') -Encoding UTF8
$dump=Get-ChildItem 'C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC' -Filter dumpbin.exe -Recurse | Where-Object FullName -Match 'Hostx64[\\/]x64' | Select-Object -First 1
if(!$dump){throw 'Dependency inspection tool not found; package not finalized.'}
$dependencies=foreach($binary in Get-ChildItem (Join-Path $destination ('prototype/out/build/win-amd64-'+$Configuration.ToLower())) -File){
 $lines=& $dump.FullName /dependents $binary.FullName
 if($LASTEXITCODE){throw 'Dependency inspection failed.'}
 [pscustomobject]@{File=$binary.Name;Imports=@($lines | Where-Object {$_ -match '^\s+\S+\.dll\s*$'} | ForEach-Object {$_.Trim()})}
}
$dependencies | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $destination 'DEPENDENCIES.json') -Encoding UTF8
if($Configuration -eq 'Release'){
 $bad=@($dependencies | ForEach-Object {$_.Imports} | Where-Object {$_ -match '^(MSVCP\d+D|MSVCP\d+D_.*|VCRUNTIME\d+(?:_\d+)?D|ucrtbased)\.dll$'})
 if($bad.Count){throw "Release package has Debug dependencies: $bad"}
 $start=Join-Path $destination 'Start Majin.cmd'
 $text=Get-Content $start -Raw
 $text=$text.Replace('scripts\launcher.ps1"','scripts\launcher.ps1" -Configuration Release')
 Set-Content $start $text -Encoding ASCII
 $readme=Join-Path $destination 'READ-ME-FIRST.txt'
 $text=Get-Content $readme -Raw
 $text=$text.Replace('Uses the tested Debug build and requires Visual C++ DEBUG runtime DLLs on','Uses previously play-tested Release binaries with an updated launcher. Requires')
 $text=$text.Replace('the development PC. The ordinary VC++ Redistributable does not supply them.','the Microsoft Visual C++ x64 runtime. No Debug CRT imports were found.')
 if($buildEvidence){$text=$text.Replace('Uses previously play-tested Release binaries with an updated launcher. Requires','Uses newly compiled Release binaries. Final gameplay retest pending. Requires')}
 Set-Content $readme $text -Encoding UTF8
}
@'
@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\collect-diagnostics.ps1"
pause
'@ | Set-Content -LiteralPath (Join-Path $destination 'Collect Diagnostics.cmd') -Encoding ASCII
$sourceRevision=& git -C $root rev-parse HEAD
if($LASTEXITCODE -ne 0){throw 'Source revision unavailable.'}
$sourceDirty=(@(& git -C $root status --porcelain).Count -gt 0)
$inventory=@(Get-ChildItem -LiteralPath $destination -File -Recurse | ForEach-Object {
 [pscustomobject]@{Path=$_.FullName.Substring($destination.Length+1).Replace('\','/');Bytes=$_.Length;SHA256=(Get-FileHash -LiteralPath $_.FullName).Hash}
})
@{Package=$name;Version=$version;SourceRevision=$sourceRevision;SourceHasLocalChanges=$sourceDirty;PublicRelease=$false;Configuration=$Configuration;Validation='Candidate; final gameplay/clean-machine retest pending';BuildEvidence=$buildEvidence;Files=$inventory} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $destination 'PACKAGE-MANIFEST.json') -Encoding UTF8
$zip=$destination+'.zip'
Compress-Archive -LiteralPath $destination -DestinationPath $zip -CompressionLevel Optimal
(Get-FileHash -LiteralPath $zip).Hash | Set-Content -LiteralPath ($zip+'.sha256') -Encoding ASCII
Write-Output "Package: $destination"
Write-Output "Archive: $zip"
