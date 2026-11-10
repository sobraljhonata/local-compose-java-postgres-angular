#Requires -Version 5.1
<#
.SYNOPSIS
  Sobe o WEB no host (ng serve) com overlay local-compose + proxy → BFF/API Compose.
  NÃO altera angular.json. Restaura environment.ts ao sair (ou use web-stop.ps1).
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$WebRoot = Join-Path (Split-Path -Parent $Root) 'autua-web-frontend'
$EnvFile = Join-Path $WebRoot 'src\app\core\config\environments\environment.ts'
$Overlay = Join-Path $Root 'config\web\environment.local-compose.ts'
$Proxy = Join-Path $Root 'config\web\proxy.local-compose.conf.js'
$StateDir = Join-Path $Root 'config\web\.runtime'
$Backup = Join-Path $StateDir 'environment.ts.bak'
$Port = if ($env:WEB_HOST_PORT) { $env:WEB_HOST_PORT } else { '14200' }

if (-not (Test-Path $WebRoot)) { throw "Clone WEB não encontrado: $WebRoot" }
if (-not (Test-Path $EnvFile)) { throw "environment.ts ausente: $EnvFile" }
if (-not (Test-Path $Overlay)) { throw "Overlay ausente: $Overlay" }
if (-not (Test-Path $Proxy)) { throw "Proxy ausente: $Proxy" }

New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
if (-not (Test-Path $Backup)) {
  Copy-Item $EnvFile $Backup -Force
  Write-Host "Backup tip → $Backup"
} else {
  Write-Host "Backup já existe; reaplicando overlay sobre tip atual."
}
Copy-Item $Overlay $EnvFile -Force
Write-Host "Overlay local-compose aplicado (BASE_URL_BFF=/autua-bff)."
Write-Host "Proxy: $Proxy → BFF/API (defaults 18081/18080)."
Write-Host "Ctrl+C restaura o tip automaticamente."

$restore = {
  if (Test-Path $Backup) {
    Copy-Item $Backup $EnvFile -Force
    Write-Host "environment.ts restaurado a partir do backup."
  }
}

try {
  Push-Location $WebRoot
  # Prefer project ng; npx fallback
  $ngArgs = @(
    'serve',
    '--host', '127.0.0.1',
    '--port', $Port,
    '--proxy-config', $Proxy
  )
  if (Test-Path (Join-Path $WebRoot 'node_modules\.bin\ng.cmd')) {
    & (Join-Path $WebRoot 'node_modules\.bin\ng.cmd') @ngArgs
  } else {
    $npxArgs = @('--yes', 'ng') + $ngArgs
    & npx @npxArgs
  }
} finally {
  Pop-Location -ErrorAction SilentlyContinue
  & $restore
}
