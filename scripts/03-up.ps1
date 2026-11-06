#Requires -Version 5.1
<#
.SYNOPSIS
  Sobe a stack Compose. BLOQUEADO até AUTUA_PHASE_B_AUTHORIZED=1.
  Não executa restore. Não usa down -v. Não encerra stack host automaticamente.
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if ($env:AUTUA_PHASE_B_AUTHORIZED -ne '1') {
  Write-Host @'
BLOQUEADO — Fase B não autorizada.
Defina AUTUA_PHASE_B_AUTHORIZED=1 somente após:
  - escolha explícita do dump PostgreSQL
  - revisão do plano em docs/phase-b-plan.md e relatório 12
  - resolução de conflito de portas com a stack host atual
Não execute restore automaticamente neste script.
'@
  exit 2
}

if (-not (Test-Path (Join-Path $Root '.env'))) {
  throw 'Crie .env a partir de .env.example antes do up.'
}

& "$PSScriptRoot\00-prereqs.ps1"
& "$PSScriptRoot\01-git-status.ps1"

$profiles = @()
if ($args -contains '-AuthMock') { $profiles += @('--profile', 'auth-mock') }
if ($args -contains '-Web') { $profiles += @('--profile', 'web') }
if ($args -contains '-WebHomolog') { $profiles += @('--profile', 'web-homolog') }

Write-Host 'Subindo postgres + api + bff (sem restore)...'
docker compose --env-file .env @profiles up -d postgres autua-api autua-bff
if ($args -contains '-AuthMock') {
  docker compose --env-file .env --profile auth-mock up -d auth-mock
}
if ($args -contains '-Web') {
  docker compose --env-file .env --profile web up -d autua-web
}
if ($args -contains '-WebHomolog') {
  docker compose --env-file .env --profile web-homolog up -d autua-web-homolog
}

docker compose --env-file .env ps
Write-Host 'Up concluído. Restore: docs/restore.md (manual, autorizado).'
