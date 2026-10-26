param([Parameter(Mandatory=$true)][string]$Archive,[Parameter(Mandatory=$true)][string]$GameDataRoot,[string]$TestRoot)
$ErrorActionPreference='Stop'
if(!$TestRoot){$testRoot=Join-Path ([Environment]::GetFolderPath('MyDocuments')) ('Majin Alpha Test/'+[Guid]::NewGuid().ToString('N'))}
if(Test-Path -LiteralPath $testRoot){throw 'Test destination already exists.'}
Expand-Archive -LiteralPath $Archive -DestinationPath $testRoot
$package=(Get-ChildItem -LiteralPath $testRoot -Directory | Select-Object -First 1).FullName
$manifest=Get-Content -LiteralPath (Join-Path $package 'PACKAGE-MANIFEST.json') -Raw | ConvertFrom-Json
$actual=@(Get-ChildItem -LiteralPath $package -File -Recurse)
if($actual.Count -ne $manifest.Files.Count+1){throw 'Package contains unlisted files'}
foreach($item in $manifest.Files){
 $path=Join-Path $package $item.Path
 if((Get-FileHash -LiteralPath $path).Hash -ne $item.SHA256){throw "Package hash mismatch: $($item.Path)"}
 if($item.Path -match '(^|/)(private|tools|reports|experiments)/|\.(iso|xex|pdb)$'){throw 'Excluded content in package'}
 if($item.Path -match '\.(jpg|png|ico)$' -and $item.Path -notin @('assets/launcher/background.png','assets/launcher/logo.png','assets/launcher/majin-fk.ico')){throw 'Unexpected visual asset in package'}
}
foreach($file in Get-ChildItem -LiteralPath (Join-Path $package 'scripts') -Filter '*.ps1'){
 $tokens=$null;$errors=$null
 $null=[System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
 if($errors.Count){throw ($errors | Out-String)}
}
. (Join-Path $package 'scripts/disc-import.ps1')
$null=Resolve-MajinGameData -Path $GameDataRoot
$preview=@(& (Join-Path $package 'scripts/run.ps1') -Preview -Configuration $manifest.Configuration -GameDataRoot $GameDataRoot)
$saveIndex=[Array]::IndexOf($preview,'--user_data_root')
if($saveIndex -lt 0 -or [IO.Path]::GetFullPath($preview[$saveIndex+1]) -ne [IO.Path]::GetFullPath((Join-Path $package 'private/runtime/user'))){throw 'Save path escaped package'}
$entry=Join-Path $package 'Majin FK Launcher.exe'
if(!(Test-Path -LiteralPath $entry) -or (Test-Path -LiteralPath (Join-Path $package 'Start Majin.cmd'))){throw 'Incorrect launcher entry point'}
$native=Start-Process -FilePath $entry -ArgumentList '--validate-only' -WorkingDirectory $env:TEMP -WindowStyle Hidden -Wait -PassThru
if($native.ExitCode -ne 0){throw 'Relocated native launcher validation failed'}
if(!(Test-Path -LiteralPath (Join-Path $package 'reports/launcher-preview.png'))){throw 'Native launcher did not render a preview'}
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class MajinLoadCheck {
 [DllImport("kernel32", CharSet=CharSet.Unicode, SetLastError=true)] public static extern IntPtr LoadLibraryEx(string path, IntPtr file, uint flags);
 [DllImport("kernel32")] public static extern bool FreeLibrary(IntPtr module);
}
"@
foreach($dll in Get-ChildItem -LiteralPath (Join-Path $package ('prototype/out/build/win-amd64-'+$manifest.Configuration.ToLower())) -Filter '*.dll'){
 $handle=[MajinLoadCheck]::LoadLibraryEx($dll.FullName,[IntPtr]::Zero,8)
 if($handle -eq [IntPtr]::Zero){throw "DLL load failed: $($dll.Name), Windows error $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"}
 [void][MajinLoadCheck]::FreeLibrary($handle)
}
Write-Output "PASS: ZIP manifest and hashes; no gameplay data/saves; allowlisted launcher artwork; native entry point; scripts parsed; ISO helper compiled; save path isolated; launcher rendered; DLLs loaded on this development PC. Gameplay and clean-machine test pending."
Write-Output "Test package: $package"
