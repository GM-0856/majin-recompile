param([ValidateSet('Debug','Release')][string]$Configuration = 'Debug',
      [ValidateSet('1280x720','1920x1080','2560x1440','3840x2160')][string]$WindowSize = '1280x720',
      [bool]$Fullscreen = $true, [bool]$VSync = $true,
      [ValidateRange(1,3)][int]$RenderScale = 1,
      [ValidateSet('none','fxaa')][string]$PostEffect = 'none',
      [ValidateSet('Default','ROV')][string]$RenderingPath = 'Default',
      [ValidateSet('Controller','KeyboardMouse')][string]$InputMode = 'Controller',
      [ValidateRange(0.01,10)][double]$MouseSensitivity = 1.0,
      [bool]$RecordPerformance = $true, [bool]$IncludeHardware = $false,
      [ValidateSet('Original','60')][string]$FrameRateMode='Original',
      [string]$GameDataRoot,
      [switch]$Preview)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'reports') | Out-Null
$projectRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'game-data.ps1')
if([string]::IsNullOrWhiteSpace($GameDataRoot)){$GameDataRoot=Get-MajinGameDataPath}
$game=Resolve-MajinGameData -Path $GameDataRoot
$build = Join-Path $projectRoot ('prototype/out/build/win-amd64-' + $Configuration.ToLower())
$exe = Join-Path $build 'majin.exe'
if (-not (Test-Path $exe)) { throw 'Build majin.exe before running.' }
. (Join-Path $PSScriptRoot 'frame-rate.ps1')
$has60=Test-Majin60Binary -Path $exe
if($FrameRateMode -eq '60' -and !$has60){throw '60 FPS requires the matching updated game binary. Use the separate 60 FPS candidate; see FPS_60.md.'}
$sessionRoot = Join-Path $projectRoot 'private/runtime'
New-Item -ItemType Directory -Force -Path $sessionRoot | Out-Null
# Persistent caches are isolated by backend, rendering path, build configuration and scale.
# Leave the old cache intact; saves retain their existing location.
$cacheKey='d3d12-'+$RenderingPath.ToLower()+'/'+$Configuration.ToLower()+'/scale-'+$RenderScale
$cacheRoot=Join-Path $sessionRoot ('cache/'+$cacheKey)
$metadataRoot=Join-Path $sessionRoot ('metadata/'+$cacheKey)
$renderTarget=if($RenderingPath -eq 'ROV'){'rov'}else{''}
$allowInvalid=($RenderingPath -eq 'ROV').ToString().ToLowerInvariant()
$logPath = Join-Path $projectRoot ('reports/runtime-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
Write-Output "Runtime log: $logPath"
$dimensions = $WindowSize.Split('x')
$launchArgs = @('--gpu_plugin','xenos','--game_data_root',$game,
    '--user_data_root',"$sessionRoot/user",'--cache_root',$cacheRoot,
    '--metadata_root',$metadataRoot,'--log_file',$logPath,
    "--window_width=$($dimensions[0])", "--window_height=$($dimensions[1])",
    "--fullscreen=$($Fullscreen.ToString().ToLowerInvariant())",
    "--vsync=$($VSync.ToString().ToLowerInvariant())",
    "--resolution_scale=$RenderScale", "--swap_post_effect=$PostEffect",
    "--render_target_path_d3d12=$renderTarget", "--gpu_allow_invalid_fetch_constants=$allowInvalid")
# Explicitly disable MnK in controller mode, even if a runtime config enables it.
$mnk = ($InputMode -eq 'KeyboardMouse').ToString().ToLowerInvariant()
$launchArgs += @("--mnk_mode=$mnk", "--mnk_mouse=$mnk")
if ($InputMode -eq 'KeyboardMouse') {
    $launchArgs += "--mnk_sensitivity=$($MouseSensitivity.ToString([Globalization.CultureInfo]::InvariantCulture))"
    $bindings = [ordered]@{
        a='Space'; b='E,Shift+Shift'; x='LMB'; y='R'
        left_trigger='Q'; right_trigger='RMB'; left_shoulder='F'; right_shoulder='C'
        lstick_up='W'; lstick_down='S'; lstick_left='A'; lstick_right='D'; lstick_press='V'
        rstick_up='I'; rstick_down='K'; rstick_left='J'; rstick_right='L'; rstick_press='MMB'
        dpad_up='Up'; dpad_down='Down'; dpad_left='Left'; dpad_right='Right'
        start='Return'; back='Tab'; guide='None'
    }
    # The SDK matches modifiers exactly. Shift+Shift binds the modifier itself;
    # shifted alternatives keep movement and other actions available while running.
    foreach ($binding in $bindings.GetEnumerator()) {
        $variants = foreach ($key in $binding.Value.Split(',')) {
            $key
            if ($key -ne 'None' -and -not $key.Contains('+')) { "Shift+$key" }
        }
        $launchArgs += "--keybind_$($binding.Key)=$($variants -join ',')"
    }
}
$launchArgs += "--majin_window_fps=$((-not $Fullscreen).ToString().ToLowerInvariant())"
$launchArgs += "--majin_record_performance=$($RecordPerformance.ToString().ToLowerInvariant())"
if($RecordPerformance){$launchArgs += "--perf_log_csv=$logPath.performance.csv"}
if($has60){$launchArgs += "--majin_60fps=$(($FrameRateMode -eq '60').ToString().ToLowerInvariant())"}
if ($Preview) { $launchArgs; return }
. (Join-Path $PSScriptRoot 'diagnostics-common.ps1')
if($IncludeHardware){
    try {Get-MajinHardwareSummary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ($logPath+'.hardware.json') -Encoding UTF8}
    catch {Write-Warning 'Optional hardware details unavailable; the game will continue.'}
}
New-Item -ItemType Directory -Force -Path $cacheRoot,$metadataRoot | Out-Null
@{Configuration=$Configuration;RenderingPath=$RenderingPath;RenderScale=$RenderScale;
    GameDataRoot=$game;CacheRoot=$cacheRoot;MetadataRoot=$metadataRoot;
    CacheFilesBefore=@(Get-ChildItem -LiteralPath $cacheRoot -File -Recurse).Count;
    FrameRateMode=$FrameRateMode;WindowSize=$WindowSize;Fullscreen=$Fullscreen;VSync=$VSync;PostEffect=$PostEffect;
    InputMode=$InputMode;MouseSensitivity=$MouseSensitivity;RecordPerformance=$RecordPerformance;IncludeHardware=$IncludeHardware} |
    ConvertTo-Json | Set-Content -LiteralPath ($logPath+'.settings.json') -Encoding UTF8
Push-Location $build
try {
    # Windows PowerShell may return immediately for a GUI executable invoked with &.
    # Wait for the actual process and read its exit code instead of $LASTEXITCODE.
    $quotedArgs = @($launchArgs | ForEach-Object {
        '"' + (($_ -replace '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
    })
    $process = Start-Process -FilePath $exe -ArgumentList $quotedArgs -WorkingDirectory $build -PassThru -Wait
    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) {
        throw "Majin exited with code $($process.ExitCode). See $logPath"
    }
} finally {
    Pop-Location
    try {
        $summary=Write-MajinPerformanceSummary -LogPath $logPath
        if($RecordPerformance -and (!$summary.Frames -or !$summary.Frames.ValidIntervals)){
            Write-Warning 'No frame samples recorded. Inspect the performance summary; an older binary may be in use.'
        }
    } catch {Write-Warning 'Diagnostic summary unavailable; game logs remain in reports.'}
}
