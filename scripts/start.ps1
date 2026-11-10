#Requires -Version 5.1
<#
.SYNOPSIS
  Sobe postgres + api + bff (+ auth-mock por padrão). NÃO restore. NÃO seed.
  Requer AUTUA_LOCAL_START_AUTHORIZED=1 (stack já em uso: não force recreate).
#>
param(
  [switch]$Web,
  [switch]$NoAuthMock
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if ($env:AUTUA_LOCAL_START_AUTHORIZED -ne '1') {
  Write-Host @'
BLOQUEADO — defina AUTUA_LOCAL_START_AUTHORIZED=1 para subir serviços.
Não executa restore/seed. Não remove volumes.
Para stack já saudável, prefira scripts\04-status.ps1 / verify.ps1.
'@
  exit 2
}
if (-not (Test-Path (Join-Path $Root '.env'))) { throw 'Crie .env a partir de .env.example.' }

$profiles = @()
if (-not $NoAuthMock) { $profiles += @('--profile', 'auth-mock') }
if ($Web) { $profiles += @('--profile', 'web') }

Write-Host 'Subindo postgres + api + bff (+ profiles)...'
docker compose --env-file .env @profiles up -d postgres autua-api autua-bff
if (-not $NoAuthMock) {
  docker compose --env-file .env --profile auth-mock up -d auth-mock
}
if ($Web) {
  Write-Host 'Profile web Compose solicitado. Em Windows, prefira scripts\web-start.ps1 (host).'
  docker compose --env-file .env --profile web up -d autua-web
}
docker compose --env-file .env ps
Write-Host 'start OK. Seed: seed-minimo.ps1 -Authorized. WEB host: web-start.ps1'
