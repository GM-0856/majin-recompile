param([string]$OutputDirectory)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$OutputDirectory){$OutputDirectory=Join-Path $root 'private/build/launcher'}
$output=[IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $output -Force | Out-Null
$vswhere=Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vs=& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if(!$vs){throw 'Visual Studio C++ build tools were not found.'}
& (Join-Path $vs 'Common7/Tools/Launch-VsDevShell.ps1') -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
$clangCommand=Get-Command clang-cl.exe -ErrorAction SilentlyContinue
$compiler=if($clangCommand){$clangCommand.Source}else{Join-Path $root 'tools/clang+llvm-20.1.8-x86_64-pc-windows-msvc/bin/clang-cl.exe'}
$source=Join-Path $root 'launcher'
$iconRoot=Join-Path $root 'assets/launcher'
Push-Location $source
try {
 & rc.exe /nologo /i $iconRoot /fo (Join-Path $output 'launcher.res') 'resource.rc'
 if($LASTEXITCODE){throw 'Launcher resource compilation failed.'}
 $exe=Join-Path $output 'Majin FK Launcher.exe'
 $object=Join-Path $output 'launcher.obj'
 & $compiler /nologo /c /O2 /MT /DNDEBUG /std:c++17 /EHsc /Brepro "/clang:-ffile-prefix-map=$root=." "/Fo$object" 'main.cpp'
 if($LASTEXITCODE){throw 'Native launcher source compilation failed.'}
 $linker=Join-Path (Split-Path $compiler -Parent) 'lld-link.exe'
 & $linker "/OUT:$exe" /SUBSYSTEM:WINDOWS /DEBUG:NONE /INCREMENTAL:NO /Brepro $object (Join-Path $output 'launcher.res') user32.lib shell32.lib
 if($LASTEXITCODE){throw 'Native launcher compilation failed.'}
 $inputs=@('launcher/main.cpp','launcher/resource.rc','launcher/launcher.manifest','assets/launcher/majin-fk.ico')
 $files=@(foreach($relative in $inputs){[ordered]@{Path=$relative;SHA256=(Get-FileHash -LiteralPath (Join-Path $root $relative)).Hash}})
 $revision=(& git -C $root rev-parse HEAD)
 if($LASTEXITCODE){throw 'Unable to resolve launcher source revision.'}
 [ordered]@{SourceRevision=$revision;File='Majin FK Launcher.exe';SHA256=(Get-FileHash -LiteralPath $exe).Hash;Configuration='Release';Subsystem='Windows GUI';Runtime='Static MSVC C++ runtime';SourceInputs=$files} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'LAUNCHER-BUILD.json') -Encoding UTF8
 Write-Output "Built native launcher: $exe"
} finally {Pop-Location}
