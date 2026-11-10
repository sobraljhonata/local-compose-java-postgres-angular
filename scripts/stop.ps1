#Requires -Version 5.1
<#
.SYNOPSIS
  Para serviços do projeto Compose atual. Nunca usa -v (preserva volumes).
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
& "$PSScriptRoot\web-stop.ps1"
docker compose --env-file .env --profile auth-mock --profile web --profile web-homolog stop
Write-Host 'Serviços parados. Volumes preservados.'
