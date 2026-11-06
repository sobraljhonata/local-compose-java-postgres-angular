#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
docker compose ps
Write-Host '--- health probes (host) ---'
$urls = @(
  'http://127.0.0.1:8080/autua-api/actuator/health',
  'http://127.0.0.1:8081/autua-bff/actuator/health',
  'http://127.0.0.1:4200/',
  'http://127.0.0.1:18082/health'
)
foreach ($u in $urls) {
  try {
    $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 5
    Write-Host ("{0,-60} {1}" -f $u, $r.StatusCode)
  } catch {
    $code = $null
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    Write-Host ("{0,-60} {1}" -f $u, $(if ($code) { $code } else { 'ERR' }))
  }
}
