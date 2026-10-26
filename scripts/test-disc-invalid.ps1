$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'disc-import.ps1')
function Assert-Rejected([byte[]]$Bytes) {
    $path=Join-Path $env:TEMP ('majin-disc-'+[Guid]::NewGuid().ToString('N')+'.iso')
    try {
        [IO.File]::WriteAllBytes($path,$Bytes)
        $rejected=$false
        try {$disc=New-Object MajinDisc.Image($path);$disc.Dispose()} catch {$rejected=$true}
        if(!$rejected){throw 'Malformed image accepted'}
    } finally {Remove-Item -LiteralPath $path -ErrorAction SilentlyContinue}
}
# Minimal filesystem fixtures exercise path safety and extent checks.
function New-Fixture([string]$Name,[uint32]$Sector=35,[uint32]$Length=4,[uint16]$Right=0) {
    $b=New-Object byte[] (36*2048)
    $magic=[Text.Encoding]::ASCII.GetBytes('MICROSOFT*XBOX*MEDIA')
    $magic.CopyTo($b,65536);$magic.CopyTo($b,65536+2028)
    [BitConverter]::GetBytes([uint32]33).CopyTo($b,65536+20)
    [BitConverter]::GetBytes([uint32]2048).CopyTo($b,65536+24)
    $p=33*2048
    [BitConverter]::GetBytes($Right).CopyTo($b,$p+2)
    [BitConverter]::GetBytes($Sector).CopyTo($b,$p+4)
    [BitConverter]::GetBytes($Length).CopyTo($b,$p+8)
    $b[$p+13]=$Name.Length
    [Text.Encoding]::ASCII.GetBytes($Name).CopyTo($b,$p+14)
    return ,$b
}
foreach($name in @('../escape','C:escape','CON','folder\escape','trailing.','NUL.txt')){Assert-Rejected (New-Fixture $name)}
Assert-Rejected (New-Fixture 'default.xex' 999999)
Assert-Rejected (New-Fixture 'default.xex' 35 4 65535)
Assert-Rejected (New-Object byte[] 12)
$xex=[IO.File]::ReadAllBytes((Join-Path (Split-Path $PSScriptRoot -Parent) 'private/game-data/default.xex'))
$security=([int]$xex[16]*16777216)+([int]$xex[17]*65536)+([int]$xex[18]*256)+$xex[19]
foreach($case in @(@(0,0,0,255,'Americas'),@(0,0,1,0,'Japan'),@(0,255,0,0,'PAL'),@(255,255,255,255,'Region-free'))) {
    for($i=0;$i -lt 4;$i++){$xex[$security+0x178+$i]=[byte]$case[$i]}
    $info=[MajinDisc.Image]::InspectXex($xex)
    if($info.Regions -notlike "*$($case[4])*"){throw 'Region mask misread'}
    if($case[4] -ne 'PAL' -and $info.Supported){throw 'Modified executable accepted'}
}
Write-Output 'PASS: unsafe names, truncated/out-of-bounds images, invalid directory links rejected; region masks decoded; modified executables incompatible.'
