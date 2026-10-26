param([Parameter(Mandatory=$true)][string]$IsoPath)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'disc-import.ps1')
$root=Split-Path $PSScriptRoot -Parent
$testRoot=Join-Path $root ('private/validation/iso-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
foreach($file in @('launcher.ps1','disc-import.ps1')) {
    $tokens=$null;$errors=$null
    $null=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file),[ref]$tokens,[ref]$errors)
    if($errors.Count){throw ($errors | Out-String)}
}
# Verify invalid images are rejected before extraction.
$bad=Join-Path $testRoot 'invalid.iso'
[IO.File]::WriteAllBytes($bad,(New-Object byte[] 70000))
$rejected=$false
try {$invalid=New-Object MajinDisc.Image($bad);$invalid.Dispose()} catch {$rejected=$true}
if(!$rejected){throw 'Invalid ISO accepted'}
$disc=New-Object MajinDisc.Image($IsoPath)
try {
    if(!$disc.Details.Supported -or $disc.Details.TitleId -ne '4E4D0816'){throw 'Known ISO not recognized'}
    $disc.Details | Format-List
    # A separate test root prevents any changes to active settings or saves.
    $selected=Import-MajinDisc -Image $disc -ProjectRoot $testRoot -Progress ([Action[int]]{param($p) if($p%10 -eq 0){Write-Host "Import $p%"}})
    if((Get-MajinGameDataPath -ProjectRoot $testRoot) -ne $selected){throw 'Imported path not persisted'}
    $local=Join-Path $root 'private/game-data'
    $checked=0
    foreach($file in Get-ChildItem -LiteralPath $local -File -Recurse) {
        $relative=$file.FullName.Substring($local.Length).TrimStart('\','/')
        $copy=Join-Path $selected $relative
        if(!(Test-Path -LiteralPath $copy) -or (Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash){throw "Import mismatch: $relative"}
        $checked++
    }
    $refused=$false
    try {$disc.Extract($selected,$null)} catch {$refused=$true}
    if(!$refused){throw 'Existing destination was not protected'}
    Write-Output "PASS: invalid ISO rejected; real ISO identified/imported; $checked local files match SHA256; configuration roundtrip; existing destination protected. Test root: $testRoot"
} finally {$disc.Dispose()}
