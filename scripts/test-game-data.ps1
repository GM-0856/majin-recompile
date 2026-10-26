$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'game-data.ps1')
$temp=Join-Path $root ('private/validation/game-data-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
function Assert($condition,$message){if(!$condition){throw $message}}
function MustFail([scriptblock]$Action){
    $failed=$false
    try {& $Action | Out-Null} catch {$failed=$true}
    Assert $failed 'Expected validation failure'
}
foreach($p in @('game-data.ps1','set-game-data.ps1','run.ps1','launcher.ps1')){
    $tokens=$null;$errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $p),[ref]$tokens,[ref]$errors)
    Assert ($errors.Count -eq 0) "Parse error: $p"
}
$valid=Resolve-MajinGameData -Path (Join-Path $root 'private/game-data')
Assert ((Get-MajinGameDataPath -ProjectRoot $temp) -eq (Join-Path $temp 'private/game-data')) 'Default path failed'
$saved=Save-MajinGameDataPath -Path $valid -ProjectRoot $temp
Assert ((Get-MajinGameDataPath -ProjectRoot $temp) -eq $valid) 'Saved path roundtrip failed'
$config=Join-Path $temp 'private/game-data.json'
$before=(Get-FileHash $config).Hash
MustFail {Save-MajinGameDataPath -Path "$temp/missing" -ProjectRoot $temp}
Assert ((Get-FileHash $config).Hash -eq $before) 'Invalid path replaced valid settings'
$bad=Join-Path $temp 'wrong game [test]'
New-Item -ItemType Directory -Path $bad | Out-Null
MustFail {Resolve-MajinGameData -Path $bad}
[IO.File]::WriteAllText((Join-Path $bad 'default.xex'),'not a supported executable')
MustFail {Resolve-MajinGameData -Path $bad}
Copy-Item -LiteralPath (Join-Path $valid 'default.xex') -Destination (Join-Path $bad 'default.xex') -Force
MustFail {Resolve-MajinGameData -Path $bad}
$preview=@(& (Join-Path $PSScriptRoot 'run.ps1') -GameDataRoot $valid -Preview)
$i=[Array]::IndexOf($preview,'--game_data_root')
Assert ($i -ge 0 -and $preview[$i+1] -eq $valid) 'Selected data root not forwarded'
$i=[Array]::IndexOf($preview,'--user_data_root')
Assert ([IO.Path]::GetFullPath($preview[$i+1]) -eq [IO.Path]::GetFullPath("$root/private/runtime/user")) 'Save root changed'
$global:MajinDataTestLaunch=$null
function Start-Process {
    param($FilePath,$ArgumentList,$WorkingDirectory,[switch]$PassThru,[switch]$Wait)
    $global:MajinDataTestLaunch=$ArgumentList -join ' '
    [pscustomobject]@{ExitCode=0}
}
try {
    & (Join-Path $PSScriptRoot 'run.ps1') -GameDataRoot $valid | Out-Null
    Assert ($global:MajinDataTestLaunch.Contains('"'+$valid+'"')) 'Native argument quoting failed'
} finally {Remove-Item Function:Start-Process}
[IO.File]::WriteAllText($config,'invalid json')
MustFail {Get-MajinGameDataPath -ProjectRoot $temp}
'PASS: parsing; supported data; config persistence; rejection of missing/wrong/incomplete data; invalid selection preserves settings; correct launch arguments and save path; mocked process launch; corrupt config rejection. No game started.'
'Test artifacts: '+$temp