# SPDX-License-Identifier: GPL-3.0-only
function Test-Majin60Binary([string]$Path) {
    # Capability detection for mixed launcher/native versions, not authentication.
    # Release hashes provide the independent file-integrity evidence.
    $stream=$null
    try {
        $stream=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        if($stream.Length -gt 512MB){return $false}
        $buffer=New-Object byte[] 65536
        $marker='majin_60fps';$tail=''
        while(($count=$stream.Read($buffer,0,$buffer.Length)) -gt 0){
            $chunk=$tail+[Text.Encoding]::ASCII.GetString($buffer,0,$count)
            if($chunk.Contains($marker)){return $true}
            $tail=$chunk.Substring([Math]::Max(0,$chunk.Length-$marker.Length+1))
        }
        return $false
    } catch {return $false}
    finally {if($stream){$stream.Dispose()}}
}
