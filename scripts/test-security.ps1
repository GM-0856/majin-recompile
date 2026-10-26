param([string]$OutputDirectory)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
if(!$OutputDirectory){$OutputDirectory=Join-Path $root ('private/security-tests/'+[Guid]::NewGuid().ToString('N'))}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
Add-Type -Path (Join-Path $PSScriptRoot 'disc-image.cs')
$script:passed=0
function Assert-Test($ok,$name){if(!$ok){throw "Security test failed: $name"};$script:passed++}
function Set-Le32($bytes,$at,[uint32]$value){[Array]::Copy([BitConverter]::GetBytes($value),0,$bytes,$at,4)}
function Set-Be32($bytes,$at,[uint32]$value){$v=[BitConverter]::GetBytes($value);[Array]::Reverse($v);[Array]::Copy($v,0,$bytes,$at,4)}
function New-Xex {
 $b=New-Object byte[] 512;[Array]::Copy([Text.Encoding]::ASCII.GetBytes('XEX2'),0,$b,0,4)
 Set-Be32 $b 16 128;Set-Be32 $b 20 1;Set-Be32 $b 24 0x40006;Set-Be32 $b 28 64
 Set-Be32 $b 68 3;Set-Be32 $b 76 0x4E4D0816;Set-Be32 $b 504 0xFF0000
 return ,$b
}
function New-Iso([string]$name='default.xex'){
 $b=New-Object byte[] 76000;$magic=[Text.Encoding]::ASCII.GetBytes('MICROSOFT*XBOX*MEDIA')
 [Array]::Copy($magic,0,$b,65536,20);[Array]::Copy($magic,0,$b,(65536+2028),20)
 Set-Le32 $b (65536+20) 34;Set-Le32 $b (65536+24) 2048
 $node=34*2048;$n=[Text.Encoding]::ASCII.GetBytes($name)
 Set-Le32 $b ($node+4) 35;Set-Le32 $b ($node+8) 512;$b[$node+13]=[byte]$n.Length
 [Array]::Copy($n,0,$b,($node+14),$n.Length);[Array]::Copy((New-Xex),0,$b,(35*2048),512)
 return ,$b
}
function Reject-Iso($bytes,$name,[string]$message=''){
 $path=Join-Path $OutputDirectory ($name+'.iso');[IO.File]::WriteAllBytes($path,$bytes)
 $rejected=$false;$image=$null
 try {$image=New-Object MajinDisc.Image($path)}catch{$rejected=$true;if($message -and $_.Exception.ToString() -notlike "*$message*"){throw}}
 finally{if($image){$image.Dispose()}}
 Assert-Test $rejected $name
}
$valid=Join-Path $OutputDirectory 'synthetic-unsupported.iso';[IO.File]::WriteAllBytes($valid,(New-Iso))
$image=New-Object MajinDisc.Image($valid)
try{
 Assert-Test (!$image.Details.Supported -and $image.Details.TitleId -eq '4E4D0816') 'synthetic XEX identity without accepting its checksum'
 $destination=Join-Path $OutputDirectory 'must-not-extract';$rejected=$false
 try{$image.Extract($destination,$null)}catch{$rejected=$true}
 Assert-Test ($rejected -and !(Test-Path -LiteralPath $destination)) 'unsupported executable cannot extract files'
}finally{$image.Dispose()}
foreach($name in @('../escape','dir/escape','dir\escape','name:stream','CON','CON.txt','CON .txt','NUL','LPT1.txt','ending.','ending ')){
 Reject-Iso (New-Iso $name) ('unsafe-'+$script:passed) 'Unsafe filename'
}
Reject-Iso (New-Object byte[] 70000) 'missing-descriptor'
$b=New-Iso;Set-Le32 $b (34*2048+4) ([uint32]::MaxValue);Reject-Iso $b 'out-of-image-sector'
$b=New-Iso;Set-Le32 $b (34*2048+8) ([uint32]::MaxValue);Reject-Iso $b 'excessive-file-size'
$b=New-Iso;Set-Le32 $b (65536+24) (32*1024*1024+1);Reject-Iso $b 'excessive-directory-size'
$b=New-Iso;$b[34*2048+13]=255;Reject-Iso $b 'unsupported-filename-bytes'
# Many overlapping file extents must not amplify a small ISO into unbounded output.
$count=10000;$tableSize=28+24*($count-1);$fileSector=[int][Math]::Ceiling((34*2048+$tableSize)/2048.0)
$b=New-Object byte[] ($fileSector*2048+2MB)
$base=New-Iso;[Array]::Copy($base,0,$b,0,($base.Length))
Set-Le32 $b (65536+24) $tableSize
for($i=0;$i -lt $count;$i++){
 $offset=if($i -eq 0){0}else{28+24*($i-1)};$node=34*2048+$offset
 [Array]::Clear($b,$node,28)
 $name=if($i -eq 0){'default.xex'}else{'f'+$i.ToString('D5')};$n=[Text.Encoding]::ASCII.GetBytes($name)
 if($i -lt $count-1){$next=if($i -eq 0){28}else{$offset+24};[Array]::Copy([BitConverter]::GetBytes([uint16]($next/4)),0,$b,($node+2),2)}
 Set-Le32 $b ($node+4) $fileSector;Set-Le32 $b ($node+8) $(if($i -eq 0){512}else{2MB})
 $b[$node+13]=[byte]$n.Length;[Array]::Copy($n,0,$b,($node+14),$n.Length)
}
[Array]::Copy((New-Xex),0,$b,($fileSector*2048),512)
Reject-Iso $b 'extraction-amplification' '16 GiB'
$random=New-Object Random(20261023)
for($i=0;$i -lt 1000;$i++){
 $b=New-Xex;$random.NextBytes($b)
 if($i%2 -eq 0){[Array]::Copy([Text.Encoding]::ASCII.GetBytes('XEX2'),0,$b,0,4)}
 try{$info=[MajinDisc.Image]::InspectXex($b);Assert-Test (!$info.Supported) 'random executable rejected by fingerprint'}
 catch{
  $inner=$_.Exception;while($inner.InnerException){$inner=$inner.InnerException}
  Assert-Test ($inner -is [IO.InvalidDataException] -or $inner -is [OverflowException]) 'malformed XEX bounds handled'
 }
}
# Exercise the actual run.ps1 quoting expression against the Windows argv parser.
$source=@'
using System; using System.Text;
public class ArgsProbe {public static int Main(string[] args){foreach(string value in args)Console.WriteLine(Convert.ToBase64String(Encoding.Unicode.GetBytes(value)));return 0;}}
'@
$probe=Join-Path $OutputDirectory 'argv-probe.exe';Add-Type -TypeDefinition $source -OutputAssembly $probe -OutputType ConsoleApplication
$run=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'run.ps1'))
$expression=[regex]::Match($run,'(?s)\$quotedArgs = @\(\$launchArgs \| ForEach-Object \{.*?\}\)').Value
if(!$expression){throw 'Could not locate the actual process argument formatter'}
$launchArgs=@('path with spaces','trailing\','embedded"quote','ampersand&value','backtick`value','literal$()value','')
& ([scriptblock]::Create($expression+'; Set-Variable -Scope 1 -Name quotedArgs -Value $quotedArgs'))
$stdout=Join-Path $OutputDirectory 'argv.txt'
$process=Start-Process -FilePath $probe -ArgumentList $quotedArgs -WorkingDirectory $env:TEMP -RedirectStandardOutput $stdout -PassThru -Wait -WindowStyle Hidden
$actual=@(Get-Content -LiteralPath $stdout | ForEach-Object{[Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($_))})
Assert-Test ($process.ExitCode -eq 0 -and $actual.Count -eq $launchArgs.Count) 'native argument count'
for($i=0;$i -lt $launchArgs.Count;$i++){Assert-Test ($actual[$i] -ceq $launchArgs[$i]) 'native argument round trip'}
[ordered]@{Checks=$script:passed;MalformedXexCases=1000;OriginalGameFilesUsed=$false;FullGameMemorySafetyCertified=$false} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'RESULTS.json') -Encoding UTF8
Write-Output "PASS: $script:passed security checks; synthetic ISO/XEX rejection and real Windows argv round trips. No game data used."
