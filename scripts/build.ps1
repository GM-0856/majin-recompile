param([ValidateSet('Debug','Release')][string]$Configuration = 'Debug')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$vswhere = 'C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe'
$vsRoot = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsRoot) { throw 'Visual Studio C++ tools not found.' }
$localClang = Join-Path $projectRoot 'tools/clang+llvm-20.1.8-x86_64-pc-windows-msvc/bin/clang.exe'
$clang = if (Test-Path $localClang) { Get-Item $localClang } else {
    Get-Item (Join-Path $vsRoot 'VC/Tools/Llvm/x64/bin/clang.exe') -ErrorAction SilentlyContinue
}
if (-not $clang) { throw 'Install the C++ Clang compiler for Windows in Visual Studio Installer.' }
$version = & $clang.FullName --version
if (($version -join ' ') -notmatch 'clang version (\d+)' -or [int]$Matches[1] -lt 20) {
    throw "Clang 20+ required. Found: $version"
}
& (Join-Path $vsRoot 'Common7/Tools/Launch-VsDevShell.ps1') -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
$cmakeRoot = Join-Path $vsRoot 'Common7/IDE/CommonExtensions/Microsoft/CMake'
$env:PATH = $clang.DirectoryName + ';' + (Join-Path $cmakeRoot 'CMake/bin') + ';' + (Join-Path $cmakeRoot 'Ninja') + ';' + $env:PATH
$sdk = Join-Path $projectRoot 'tools/rexglue-sdk-0.10.0/win-amd64'
$preset = 'win-amd64-' + $Configuration.ToLower()
if(Get-Process majin -ErrorAction SilentlyContinue){throw 'Close Majin before rebuilding.'}
& (Join-Path $PSScriptRoot 'build-patched-runtime.ps1') -Configuration $Configuration
Push-Location (Join-Path $projectRoot 'prototype')
try {
    # Never compile a forced diagnostic generation: require strict codegen first.
    & (Join-Path $sdk 'bin/rexglue.exe') codegen 'majin_manifest.toml'
    if ($LASTEXITCODE -ne 0) { throw 'Codegen validation failed.' }
    cmake --fresh --preset $preset "-DCMAKE_PREFIX_PATH=$sdk"
    if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed.' }
    cmake --build --preset $preset --parallel 2
    if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
} finally {
    Pop-Location
}

& (Join-Path $PSScriptRoot 'test-frame-timing.ps1')
# CMake copies the packaged SDK runtime. Install the validated patched build last.
$suffix=if($Configuration -eq 'Debug'){'d'}else{''}
$runtime=Join-Path $projectRoot "tools/source/rexglue-sdk-audio-debug/out/win-amd64/$Configuration/rexruntime$suffix.dll"
$target=Join-Path $projectRoot "prototype/out/build/$preset/rexruntime$suffix.dll"
Copy-Item -LiteralPath $runtime -Destination $target -Force
if((Get-FileHash $runtime).Hash -ne (Get-FileHash $target).Hash){throw 'Patched runtime verification failed.'}
$gpu=Join-Path $projectRoot "tools/source/rexglue-sdk-audio-debug/out/win-amd64/$Configuration/rexgpu-xenos$suffix.dll"
$gpuTarget=Join-Path $projectRoot "prototype/out/build/$preset/rexgpu-xenos$suffix.dll"
Copy-Item -LiteralPath $gpu -Destination $gpuTarget -Force
if((Get-FileHash $gpu).Hash -ne (Get-FileHash $gpuTarget).Hash){throw 'Patched GPU verification failed.'}
Write-Output 'Game build complete; XMA recovery runtime and local Release frame capture GPU installed.'
