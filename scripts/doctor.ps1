#Requires -Version 5.1
<#
.SYNOPSIS
  Diagnóstico não destrutivo do ambiente local-compose + clones.
#>
$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
$Parent = Split-Path -Parent $Root
Set-Location $Root

function Ok($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Warn($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }
function Bad($m) { Write-Host "[XX] $m" -ForegroundColor Red }

Write-Host "=== doctor autua-local-compose ==="

# Docker
try {
  docker version --format '{{.Server.Version}}' | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "Docker Engine" } else { Bad "Docker Engine" }
} catch { Bad "Docker Engine: $_" }
try {
  docker compose version | Out-Null
  if ($LASTEXITCODE -eq 0) { Ok "Docker Compose" } else { Bad "Docker Compose" }
} catch { Bad "Docker Compose: $_" }

# Clones
foreach ($n in @('autua-api','autua-bff','autua-web-frontend','autua-app')) {
  $p = Join-Path $Parent $n
  if (Test-Path $p) { Ok "Clone $n" } else { Bad "Clone ausente: $p" }
}

# Tooling
foreach ($cmd in @('java','mvn','node','npm')) {
  if (Get-Command $cmd -ErrorAction SilentlyContinue) { Ok $cmd } else { Warn "$cmd não no PATH" }
}
if (Get-Command fvm -ErrorAction SilentlyContinue) { Ok 'fvm' }
elseif (Get-Command flutter -ErrorAction SilentlyContinue) { Ok 'flutter' }
else { Warn 'Flutter/FVM não no PATH' }
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (Test-Path $adb) { Ok "adb ($adb)" } else { Warn 'adb não encontrado no SDK padrão' }

# Config
if (Test-Path (Join-Path $Root '.env')) { Ok '.env presente' } else { Warn '.env ausente — copie .env.example' }
if (Test-Path (Join-Path $Root '.env.example')) { Ok '.env.example' } else { Bad '.env.example' }
if (Test-Path (Join-Path $Root 'config\web\proxy.local-compose.conf.js')) { Ok 'proxy WEB local-compose' } else { Bad 'proxy WEB' }
if (Test-Path (Join-Path $Root 'ensaios\gd-mvp-rc1-b33-seed\10-seed-institucional-sintetico.sql')) { Ok 'seed 10' } else { Bad 'seed 10' }

# compose config (não sobe nada)
if (Test-Path (Join-Path $Root '.env')) {
  docker compose --env-file .env config --quiet 2>$null
  if ($LASTEXITCODE -eq 0) { Ok 'docker compose config' } else { Warn 'docker compose config falhou (revise .env)' }
} else {
  Warn 'compose config pulado (.env ausente)'
}

# Portas (informativo)
Write-Host "`nPortas típicas (verifique conflito): 5434, 18080, 18081, 14200, 18082"
Write-Host "doctor concluído."
