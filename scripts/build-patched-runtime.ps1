param([ValidateSet('Debug','Release')][string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$source=Join-Path $root 'tools/source/rexglue-sdk-audio-debug'
$patchRoot=Join-Path $root 'patches/rexglue-0.10.0'
$revision='f5337cdc947ff6d4c4196737e2c807a48f2a1fc2'
function Check-Native($step) { if($LASTEXITCODE -ne 0){throw "$step failed (exit $LASTEXITCODE)."} }
if(!(Test-Path "$source/.git")) {
    if(Test-Path $source){throw "Existing directory is not the expected SDK checkout: $source"}
    git clone --branch v0.10.0 --depth 1 https://github.com/rexglue/rexglue-sdk.git $source
    Check-Native 'SDK clone'
}
$head=git -C $source rev-parse HEAD
Check-Native 'SDK revision check'
if($head -ne $revision){throw "SDK revision mismatch; expected $revision, found $head."}
$modules=@('cli11','libmspack','FFmpeg','tomlplusplus','simde','xxHash','spdlog','fmt','utfcpp','imgui','sdl3','tracy','o1heap','inja')
foreach($name in $modules){
    $expected=(git -C $source ls-tree HEAD "thirdparty/$name") -split '\s+'
    Check-Native 'Submodule reference'
    $module=Join-Path $source "thirdparty/$name"
    $actual=''
    if(Test-Path "$module/.git"){$actual=git -C $module rev-parse HEAD; Check-Native 'Submodule revision'}
    if($actual -ne $expected[2]){
        git -C $source submodule update --init --depth 1 -- "thirdparty/$name"
        Check-Native "Dependency $name"
    }
}
# Git without symlink support writes small relative-path placeholders on Windows.
$module=Join-Path $source 'thirdparty/libmspack'
git -C $module ls-files -s | ForEach-Object {
    if($_ -match '^120000 .*\t(.+)$'){
        $dest=Join-Path $module $Matches[1]
        $item=Get-Item -LiteralPath $dest
        if(!($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $item.Length -lt 256){
            $relative=(Get-Content -LiteralPath $dest -Raw).Trim()
            $target=[IO.Path]::GetFullPath((Join-Path (Split-Path $dest -Parent) $relative))
            if(!$target.StartsWith($module+[IO.Path]::DirectorySeparatorChar)){throw 'Dependency link leaves module.'}
            Copy-Item -LiteralPath $target -Destination $dest -Force
        }
    }
}
# Remove only our exact optional timing patch before the base patch checks.
# This makes repeated builds idempotent and still rejects unrelated edits.
$fpsPatch=Join-Path $patchRoot 'fps60.patch'
git -C $source apply --reverse --check $fpsPatch 2>$null
if($LASTEXITCODE -eq 0){
 git -C $source apply --reverse $fpsPatch
 Check-Native 'Prior timing patch removal'
}
$patch=Join-Path $patchRoot 'xma-context.patch'
git -C $source apply --reverse --check $patch 2>$null
if($LASTEXITCODE -ne 0){
    git -C $source apply --check $patch
    Check-Native 'XMA patch check'
    git -C $source apply $patch
    Check-Native 'XMA patch application'
}
Copy-Item (Join-Path $patchRoot 'empty_packet_recovery.h') "$source/src/audio/empty_packet_recovery.h" -Force
Copy-Item (Join-Path $patchRoot 'empty_packet_recovery_test.cpp') "$source/src/audio/empty_packet_recovery_test.cpp" -Force
# Bound only the known repeated texture warning; retain samples and counts.
$loggingPatch=Join-Path $patchRoot 'texture-warning-logging.patch'
git -C $source apply --reverse --check $loggingPatch 2>$null
if($LASTEXITCODE -ne 0 -and !([IO.File]::ReadAllText((Join-Path $source 'src/core/logging.cpp')).Contains('if (name == "gpu") sinks = {std::make_shared<majin::TextureWarningSink>(std::move(sinks))};'))){
 git -C $source apply --check $loggingPatch
 Check-Native 'Texture logging patch check'
 git -C $source apply $loggingPatch
 Check-Native 'Texture logging patch application'
}
$flushPatch=Join-Path $patchRoot 'texture-warning-flush.patch'
git -C $source apply --reverse --check $flushPatch 2>$null
if($LASTEXITCODE -ne 0){
 git -C $source apply --check $flushPatch
 Check-Native 'Texture flush patch check'
 git -C $source apply $flushPatch
 Check-Native 'Texture flush patch application'
}
Copy-Item -LiteralPath (Join-Path $patchRoot 'texture_warning_sink.h') -Destination (Join-Path $source 'src/core/texture_warning_sink.h') -Force
# Enable only local frame CSV in Release; keep the ordinary graphics backend.
Copy-Item -LiteralPath (Join-Path $patchRoot 'release_frame_timing.h') -Destination (Join-Path $source 'src/graphics/release_frame_timing.h') -Force
$framePatch=Join-Path $patchRoot 'release-frame-capture.patch'
git -C $source apply --reverse --check $framePatch 2>$null
if($LASTEXITCODE -ne 0){
 $legacyFramePatch=Join-Path $patchRoot 'release-frame-capture-legacy.patch'
 git -C $source apply --reverse --check $legacyFramePatch 2>$null
 if($LASTEXITCODE -eq 0){
  git -C $source apply --reverse $legacyFramePatch
  Check-Native 'Prior frame patch migration'
 }
 git -C $source apply --check $framePatch
 Check-Native 'Release frame capture patch check'
 git -C $source apply $framePatch
 Check-Native 'Release frame capture patch application'
}
# Refuse unrelated/abandoned graphics experiments before building the plugin.
$frameExpected=Get-Content -LiteralPath (Join-Path $patchRoot 'release-frame-capture.json') -Raw | ConvertFrom-Json
$frameText=[IO.File]::ReadAllText((Join-Path $source $frameExpected.Path)).Replace("`r`n","`n")
$hasher=[Security.Cryptography.SHA256]::Create()
try{$frameHash=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($frameText)))).Replace('-','')}finally{$hasher.Dispose()}
if($frameHash -ne $frameExpected.NormalizedPatchedSHA256){throw 'Unexpected command-processor changes; use a clean pinned SDK checkout.'}
$graphicsChanges=@(git -C $source diff --name-only -- src/graphics)
Check-Native 'Graphics source audit'
if(@($graphicsChanges | Where-Object {$_ -ne $frameExpected.Path}).Count){throw 'Unrelated GPU source modifications detected; use a clean pinned SDK checkout.'}
git -C $source apply --check $fpsPatch
Check-Native '60 FPS patch check'
git -C $source apply $fpsPatch
Check-Native '60 FPS patch application'
Copy-Item -LiteralPath (Join-Path $patchRoot 'frame_deadline.h') -Destination (Join-Path $source 'src/graphics/frame_deadline.h') -Force
$fpsExpected=Get-Content -LiteralPath (Join-Path $patchRoot 'fps60.json') -Raw | ConvertFrom-Json
foreach($item in $fpsExpected.Files){
 $normalized=[IO.File]::ReadAllText((Join-Path $source $item.Path)).Replace("`r`n","`n")
 $hasher=[Security.Cryptography.SHA256]::Create()
 try{$hash=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized)))).Replace('-','')}finally{$hasher.Dispose()}
 if($hash -ne $item.NormalizedPatchedSHA256){throw 'Unexpected optional timing source; use a clean pinned SDK checkout.'}
}
$vsRoot=& 'C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe' -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if(!$vsRoot){throw 'Visual Studio C++ tools required.'}
& (Join-Path $vsRoot 'Common7/Tools/Launch-VsDevShell.ps1') -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
$cmakeRoot=Join-Path $vsRoot 'Common7/IDE/CommonExtensions/Microsoft/CMake'
$clangDir=Join-Path $root 'tools/clang+llvm-20.1.8-x86_64-pc-windows-msvc/bin'
if(!(Test-Path "$clangDir/clang++.exe")){$clangDir=Join-Path $vsRoot 'VC/Tools/Llvm/x64/bin'}
$env:PATH=$clangDir+';'+(Join-Path $cmakeRoot 'CMake/bin')+';'+(Join-Path $cmakeRoot 'Ninja')+';'+$env:PATH
Push-Location $source
try {
    New-Item -ItemType Directory -Force out | Out-Null
    clang++ -std=c++20 src/audio/empty_packet_recovery_test.cpp -o out/empty_packet_recovery_test.exe
    Check-Native 'XMA test compilation'
    & ./out/empty_packet_recovery_test.exe
    Check-Native 'XMA boundary tests'
    clang++ -std=c++20 "-I$source/thirdparty/spdlog/include" "-I$source/thirdparty/fmt/include" (Join-Path $patchRoot 'texture_warning_sink_test.cpp') -o out/texture_warning_sink_test.exe
    Check-Native 'Texture logging test compilation'
    & ./out/texture_warning_sink_test.exe
    Check-Native 'Texture logging tests'
    cmake --preset win-amd64 -DREXGLUE_BUILD_TESTS=OFF
    Check-Native 'SDK configuration'
    cmake --build out/build/win-amd64 --config $Configuration --target rexruntime rexgpu-xenos --parallel 4
    Check-Native 'SDK runtime build'
} finally {Pop-Location}
Write-Output "Patched $Configuration runtime built; XMA boundary tests passed."
