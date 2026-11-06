#Requires -Version 5.1
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('autua-api', 'autua-bff', 'autua-web', 'autua-web-homolog', 'auth-mock', 'postgres')]
  [string]$Service
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
$env:DOCKER_BUILDKIT = '1'

if ($Service -eq 'postgres') {
  Write-Host 'postgres usa imagem oficial — apenas recreate (sem wipe de volume)'
  docker compose up -d --no-deps --force-recreate postgres
  exit 0
}

Write-Host "Rebuild $Service from local clone / dockerfile"
& "$PSScriptRoot\01-git-status.ps1"
docker compose build $Service
if ($env:AUTUA_PHASE_B_AUTHORIZED -eq '1') {
  docker compose up -d --no-deps $Service
} else {
  Write-Host 'Imagem reconstruída. Recreate/up bloqueado até AUTUA_PHASE_B_AUTHORIZED=1'
}
