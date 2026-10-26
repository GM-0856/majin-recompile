# ISO import helpers; independent of WinForms and external extractors.
. (Join-Path $PSScriptRoot 'game-data.ps1')
if(-not ('MajinDisc.Image' -as [type])) {Add-Type -Path (Join-Path $PSScriptRoot 'disc-image.cs')}
function Import-MajinDisc {
    param([Parameter(Mandatory=$true)]$Image,
          [string]$ProjectRoot=(Split-Path $PSScriptRoot -Parent),
          [Action[int]]$Progress)
    if(!$Image.Details.Supported){throw 'Unsupported game or executable revision. No files were imported.'}
    $container=Join-Path $ProjectRoot 'private/imports'
    New-Item -ItemType Directory -Path $container -Force | Out-Null
    $drive=New-Object System.IO.DriveInfo([System.IO.Path]::GetPathRoot((Resolve-Path -LiteralPath $container).ProviderPath))
    if($drive.AvailableFreeSpace -lt ($Image.Details.Bytes+256MB)){throw 'Not enough free space to import this image (plus 256 MB reserve).'}
    $id=[Guid]::NewGuid().ToString('N')
    $staging=Join-Path $container ('incomplete-'+$id)
    $complete=Join-Path $container ('majin-'+$id)
    try {
        $Image.Extract($staging,$Progress)
        $null=Resolve-MajinGameData -Path $staging
        Move-Item -LiteralPath $staging -Destination $complete
        return (Save-MajinGameDataPath -Path $complete -ProjectRoot $ProjectRoot)
    } catch {
        throw "Import did not complete: $($_.Exception.Message) Previous settings and saves are unchanged. Partial files, if any, remain in $staging"
    }
}
