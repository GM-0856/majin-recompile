param([string]$OutputDirectory,[switch]$AddressSanitizer)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$OutputDirectory){$OutputDirectory=Join-Path $root ('private/timing-tests/'+[Guid]::NewGuid().ToString('N'))}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$vs=& 'C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe' -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if(!$vs){throw 'Visual Studio C++ tools required for timing tests.'}
& (Join-Path $vs 'Common7/Tools/Launch-VsDevShell.ps1') -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
$clang=Join-Path $root 'tools/clang+llvm-20.1.8-x86_64-pc-windows-msvc/bin/clang++.exe'
if(!(Test-Path -LiteralPath $clang)){$clang=Join-Path $vs 'VC/Tools/Llvm/x64/bin/clang++.exe'}
$flags=@('-std=c++20','-Wall','-Wextra','-Werror')
if($AddressSanitizer){
 $flags+=@('-fsanitize=address','-g')
 $resource=(& $clang -print-resource-dir).Trim()
 $asan=Join-Path $resource 'lib/windows/clang_rt.asan_dynamic-x86_64.dll'
 if(!(Test-Path -LiteralPath $asan)){throw 'Clang AddressSanitizer runtime not installed.'}
 Copy-Item -LiteralPath $asan -Destination $OutputDirectory -Force
}
$tests=@(@('menu',(Join-Path $root 'prototype/tests/equivalent_counter_test.cpp'),(Join-Path $root 'prototype/src')),
         @('deadline',(Join-Path $root 'patches/rexglue-0.10.0/frame_deadline_test.cpp'),(Join-Path $root 'patches/rexglue-0.10.0')))
foreach($test in $tests){
 $exe=Join-Path $OutputDirectory ($test[0]+'.exe')
 & $clang @flags ('-I'+$test[2]) $test[1] -o $exe
 if($LASTEXITCODE){throw 'Timing test compilation failed.'}
 & $exe
 if($LASTEXITCODE){throw ('Timing assertions or sanitizer failed: exit '+$LASTEXITCODE)}
}
Write-Output ('PASS: standalone timing boundary tests; AddressSanitizer='+[bool]$AddressSanitizer+'. No full-game sanitizer coverage is claimed.')
