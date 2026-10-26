param([Parameter(Mandatory=$true)][string]$InputImage,[Parameter(Mandatory=$true)][string]$OutputIcon)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$source=[Drawing.Image]::FromFile($InputImage)
$frames=New-Object 'System.Collections.Generic.List[byte[]]'
$sizes=@(16,24,32,48,64,128,256)
try {
 foreach($size in $sizes){
  $bitmap=New-Object Drawing.Bitmap($size,$size,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $graphics=[Drawing.Graphics]::FromImage($bitmap)
  $stream=New-Object IO.MemoryStream
  try {
   $graphics.Clear([Drawing.Color]::Transparent)
   $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
   $graphics.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality
   $scale=[Math]::Min($size/[double]$source.Width,$size/[double]$source.Height)
   $width=[int][Math]::Round($source.Width*$scale);$height=[int][Math]::Round($source.Height*$scale)
   $graphics.DrawImage($source,[int](($size-$width)/2),[int](($size-$height)/2),$width,$height)
   $bitmap.Save($stream,[Drawing.Imaging.ImageFormat]::Png)
   $frames.Add($stream.ToArray())
  } finally {$stream.Dispose();$graphics.Dispose();$bitmap.Dispose()}
 }
 $file=[IO.File]::Create($OutputIcon);$writer=New-Object IO.BinaryWriter($file)
 try {
  $writer.Write([uint16]0);$writer.Write([uint16]1);$writer.Write([uint16]$sizes.Count)
  $offset=6+16*$sizes.Count
  for($i=0;$i -lt $sizes.Count;$i++){
   $dimension=if($sizes[$i] -eq 256){0}else{$sizes[$i]}
   $writer.Write([byte]$dimension);$writer.Write([byte]$dimension);$writer.Write([byte]0);$writer.Write([byte]0)
   $writer.Write([uint16]1);$writer.Write([uint16]32);$writer.Write([uint32]$frames[$i].Length);$writer.Write([uint32]$offset)
   $offset+=$frames[$i].Length
  }
  foreach($frame in $frames){$writer.Write($frame)}
 } finally {$writer.Dispose();$file.Dispose()}
 Write-Output 'Created multi-resolution ICO: 16, 24, 32, 48, 64, 128 and 256 pixels.'
} finally {$source.Dispose()}
