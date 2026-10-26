param([string]$OutputDirectory)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'frame-rate.ps1')
if(!$OutputDirectory){$OutputDirectory=Join-Path $env:TEMP ('Majin capability '+[Guid]::NewGuid().ToString('N'))}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$path=Join-Path $OutputDirectory 'synthetic.dat'
function Check($ok,$message){if(!$ok){throw $message}}
Check (!(Test-Majin60Binary $path)) 'Missing executable must not enable the option'
[IO.File]::WriteAllText($path,'Legacy placeholder',[Text.Encoding]::ASCII)
Check (!(Test-Majin60Binary $path)) 'Legacy executable misidentified'
[IO.File]::WriteAllText($path,('x'*65531)+'majin_60fps',[Text.Encoding]::ASCII)
Check (Test-Majin60Binary $path) 'Read-boundary marker missed'
[IO.File]::WriteAllText($path,'majin_60fps',[Text.Encoding]::ASCII)
Check (Test-Majin60Binary $path) 'Marker at EOF missed'
[IO.File]::WriteAllText($path,'MAJIN_60FPS',[Text.Encoding]::ASCII)
Check (!(Test-Majin60Binary $path)) 'Case-sensitive flag name was not respected'
[IO.File]::WriteAllBytes($path,(New-Object byte[] 0))
Check (!(Test-Majin60Binary $path)) 'Empty executable misidentified'
Write-Output 'PASS: 6 capability checks; missing/legacy/boundary/EOF/case/empty inputs. No executable launched.'
