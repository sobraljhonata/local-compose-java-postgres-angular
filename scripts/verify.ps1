#Requires -Version 5.1
<#
.SYNOPSIS
  Smoke não destrutivo: health TCP/HTTP dos serviços locais.
#>
$ErrorActionPreference = 'Continue'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Probe([string]$Name, [string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8
    Write-Host "[OK] $Name $($r.StatusCode) $Url"
  } catch {
    $code = $null
    try { $code = [int]$_.Exception.Response.StatusCode } catch {}
    if ($code) { Write-Host "[!!] $Name HTTP $code $Url" -ForegroundColor Yellow }
    else { Write-Host "[XX] $Name FAIL $Url — $($_.Exception.Message)" -ForegroundColor Red }
  }
}

# Portas do .env ou defaults remapeados documentados
$api = if ($env:API_HOST_PORT) { $env:API_HOST_PORT } else { '18080' }
$bff = if ($env:BFF_HOST_PORT) { $env:BFF_HOST_PORT } else { '18081' }
$auth = if ($env:AUTH_MOCK_HOST_PORT) { $env:AUTH_MOCK_HOST_PORT } else { '18082' }
$web = if ($env:WEB_HOST_PORT) { $env:WEB_HOST_PORT } else { '14200' }

if (Test-Path (Join-Path $Root '.env')) {
  Get-Content (Join-Path $Root '.env') | ForEach-Object {
    if ($_ -match '^\s*API_HOST_PORT=(.+)$') { $api = $Matches[1].Trim() }
    if ($_ -match '^\s*BFF_HOST_PORT=(.+)$') { $bff = $Matches[1].Trim() }
    if ($_ -match '^\s*AUTH_MOCK_HOST_PORT=(.+)$') { $auth = $Matches[1].Trim() }
    if ($_ -match '^\s*WEB_HOST_PORT=(.+)$') { $web = $Matches[1].Trim() }
  }
}

Write-Host "=== verify (api=$api bff=$bff auth=$auth web=$web) ==="
Probe 'api-health' "http://127.0.0.1:$api/autua-api/actuator/health"
Probe 'bff-info' "http://127.0.0.1:$bff/autua-bff/actuator/info"
Probe 'auth-jwks' "http://127.0.0.1:$auth/realms/autua-local/protocol/openid-connect/certs"
Probe 'web' "http://127.0.0.1:$web/"
docker compose --env-file .env ps 2>$null
Write-Host 'verify concluído (não cria Enrollment).'
