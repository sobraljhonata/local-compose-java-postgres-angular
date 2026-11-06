#Requires -Version 5.1
<#
.SYNOPSIS
  Para containers do projeto autua-local. PRESERVA volumes (nunca -v).
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
Write-Host 'docker compose down (sem -v) — volumes preservados'
docker compose --profile web --profile web-homolog --profile auth-mock down
Write-Host 'Concluído. Volume autua_local_compose_pgdata mantido.'
