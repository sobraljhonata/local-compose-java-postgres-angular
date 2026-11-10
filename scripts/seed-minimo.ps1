#Requires -Version 5.1
<#
.SYNOPSIS
  Aplica seed institucional sintético mínimo (10) — local-ok / órgão 919001.
  NÃO executa restore. NÃO roda seeds 30/31. Idempotente (NOT EXISTS).
.PARAMETER Authorized
  Exige -Authorized para executar (evita seed acidental).
#>
param(
  [switch]$Authorized
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Seed = Join-Path $Root 'ensaios\gd-mvp-rc1-b33-seed\10-seed-institucional-sintetico.sql'

if (-not $Authorized) {
  Write-Host @'
BLOQUEADO — seed mínimo não autorizado.
Reexecute com: .\scripts\seed-minimo.ps1 -Authorized
Aplica somente 10-seed-institucional-sintetico.sql (dados sintéticos).
'@
  exit 2
}
if (-not (Test-Path $Seed)) { throw "Seed ausente: $Seed" }

# Ler senha do .env se presente
$envFile = Join-Path $Root '.env'
if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*POSTGRES_PASSWORD=(.+)$') { $env:PGPASSWORD = $Matches[1].Trim() }
    if ($_ -match '^\s*POSTGRES_USER=(.+)$') { $script:PgUser = $Matches[1].Trim() }
    if ($_ -match '^\s*POSTGRES_DB=(.+)$') { $script:PgDb = $Matches[1].Trim() }
  }
}
if (-not $env:PGPASSWORD) { throw 'Defina POSTGRES_PASSWORD no .env' }
$PgUser = if ($script:PgUser) { $script:PgUser } else { 'autua' }
$PgDb = if ($script:PgDb) { $script:PgDb } else { 'autua_local' }

Write-Host "Aplicando seed 10 em container autua-local-postgres ($PgDb)..."
Get-Content -Raw $Seed | docker exec -i -e PGPASSWORD=$env:PGPASSWORD autua-local-postgres `
  psql -U $PgUser -d $PgDb -v ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) { throw "psql exit $LASTEXITCODE" }

Write-Host 'Verificando fixture local-ok...'
docker exec -e PGPASSWORD=$env:PGPASSWORD autua-local-postgres `
  psql -U $PgUser -d $PgDb -c "SELECT usu_id_usuario, usu_num_cpf, usu_id_instituicao FROM radar_relacional.tb_usuario WHERE usu_num_cpf='39053344705';"
Write-Host 'Seed mínimo OK.'
