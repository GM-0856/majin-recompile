# Shared, non-interactive game-data configuration. No game files are copied.
function Get-MajinGameDataPath {
    param([string]$ProjectRoot=(Split-Path $PSScriptRoot -Parent))
    $config=Join-Path $ProjectRoot 'private/game-data.json'
    if(Test-Path -LiteralPath $config){
        try {
            $saved=Get-Content -LiteralPath $config -Raw | ConvertFrom-Json
            if([string]::IsNullOrWhiteSpace([string]$saved.GameDataRoot)){throw 'Empty path'}
            return [string]$saved.GameDataRoot
        } catch {throw 'Game-data settings are unreadable. Run set-game-data.ps1 again.'}
    }
    return (Join-Path $ProjectRoot 'private/game-data')
}
function Resolve-MajinGameData {
    param([Parameter(Mandatory=$true)][string]$Path)
    if(!(Test-Path -LiteralPath $Path -PathType Container)){throw 'Choose the extracted game folder, not an ISO or executable.'}
    $resolved=(Resolve-Path -LiteralPath $Path).ProviderPath
    $xex=Join-Path $resolved 'default.xex'
    if(!(Test-Path -LiteralPath $xex -PathType Leaf)){throw 'default.xex was not found in the selected folder.'}
    $expected='660CAE389F0A45100739F935472437D282B2568FCFC2C60FC5A9B2B7B48CE1EC'
    if((Get-FileHash -LiteralPath $xex -Algorithm SHA256).Hash -ne $expected){
        throw 'This executable does not match the supported game build. Other revisions and modified executables are not supported yet.'
    }
    foreach($relative in @('finalizedXBox360/KB','finalizedXBox360/system')){
        $folder=Join-Path $resolved $relative
        if(!(Test-Path -LiteralPath $folder -PathType Container)){throw "Required game-data folder is missing: $relative"}
        if(!(Get-ChildItem -LiteralPath $folder -File -Recurse | Select-Object -First 1)){throw "Required game-data folder is empty: $relative"}
    }
    return $resolved
}
function Save-MajinGameDataPath {
    param([Parameter(Mandatory=$true)][string]$Path,
          [string]$ProjectRoot=(Split-Path $PSScriptRoot -Parent))
    $resolved=Resolve-MajinGameData -Path $Path
    $folder=Join-Path $ProjectRoot 'private'
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $config=Join-Path $folder 'game-data.json'
    $temp=Join-Path $folder ('game-data.'+[Guid]::NewGuid().ToString('N')+'.tmp')
    try {
        @{GameDataRoot=$resolved} | ConvertTo-Json | Set-Content -LiteralPath $temp -Encoding UTF8
        Move-Item -LiteralPath $temp -Destination $config -Force
    } finally {if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}}
    return $resolved
}