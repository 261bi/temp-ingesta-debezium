$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

& (Join-Path $PSScriptRoot 'register-source.ps1') | Out-Null
& (Join-Path $PSScriptRoot 'register-sink.ps1') | Out-Null

Invoke-RestMethod -Method Get -Uri 'http://localhost:38083/connectors'