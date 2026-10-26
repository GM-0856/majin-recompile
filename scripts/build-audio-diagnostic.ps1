param([ValidateSet('Debug','Release')][string]$Configuration='Debug')
# Backward-compatible entry point; canonical patch is maintained under patches/.
& (Join-Path $PSScriptRoot 'build-patched-runtime.ps1') -Configuration $Configuration
