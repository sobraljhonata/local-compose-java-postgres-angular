#Requires -Version 5.1
<#
.SYNOPSIS
  Valida pré-requisitos da stack autua-local-compose (Fase A/B).
  Não inicia containers. Não altera Git.
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

function Test-Cmd($name) {
  $c = Get-Command $name -EA SilentlyContinue
  if (-not $c) { throw "Comando ausente: $name" }
  Write-Host "OK $name -> $($c.Source)"
}

Test-Cmd docker
docker version --format '{{.Server.Version}}' | ForEach-Object { Write-Host "OK docker engine $_" }

foreach ($rel in @('..\autua-api', '..\autua-bff', '..\autua-web-frontend')) {
  $p = Join-Path $Root $rel
  if (-not (Test-Path $p)) { throw "Clone ausente: $p" }
  Write-Host "OK clone $p"
}

$ports = @(4200, 8080, 8081, 5433, 18082)
Write-Host '--- Portas (LISTEN) ---'
foreach ($port in $ports) {
  $hits = Get-NetTCPConnection -LocalPort $port -State Listen -EA SilentlyContinue
  if ($hits) {
    Write-Host "OCUPADA $port PID(s): $(($hits.OwningProcess | Select-Object -Unique) -join ',')"
  } else {
    Write-Host "LIVRE   $port"
  }
}

Write-Host '--- Volumes críticos ---'
docker volume ls --format '{{.Name}}' | Select-String 'autua_gd_pgdata_local|autua_local_compose_pgdata|autua-e2e-pgdata'

Write-Host 'Pré-requisitos verificados. Conflitos de porta devem ser resolvidos antes da Fase B.'
