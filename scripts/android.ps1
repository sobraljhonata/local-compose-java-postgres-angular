#Requires -Version 5.1
<#
.SYNOPSIS
  Prepara ADB reverse e imprime comando de build Flutter debug/local.
  NÃO instala APK nem limpa dados sem -InstallConfirm.
#>
param(
  [switch]$InstallConfirm,
  [string]$BffHostPort = '18081',
  [string]$ReversePort = '8081'
)
$ErrorActionPreference = 'Stop'
$AppRoot = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'autua-app'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { throw "adb não encontrado: $adb" }
if (-not (Test-Path $AppRoot)) { throw "Clone APP ausente: $AppRoot" }

Write-Host '=== devices ==='
& $adb devices -l
Write-Host "=== reverse tcp:$ReversePort → tcp:$BffHostPort ==="
& $adb reverse --remove-all 2>$null
& $adb reverse "tcp:$ReversePort" "tcp:$BffHostPort"
& $adb reverse "tcp:$BffHostPort" "tcp:$BffHostPort"
& $adb reverse tcp:18082 tcp:18082
& $adb reverse --list

Write-Host @'

Build sugerido (COR-QR deve estar no clone APP; QR HTTP só ENV=local debug):

  cd autua-app
  fvm flutter build apk --debug `
    --dart-define=ENV=local `
    --dart-define=BASE_URL=http://127.0.0.1:8081/ `
    --dart-define=BFF_URL=http://127.0.0.1:8081/autua-bff/

'@

if ($InstallConfirm) {
  $apk = Join-Path $AppRoot 'build\app\outputs\flutter-apk\app-debug.apk'
  if (-not (Test-Path $apk)) { throw "APK ausente: $apk — build primeiro" }
  Write-Host "Install -r $apk"
  & $adb install -r $apk
} else {
  Write-Host 'Install omitido (passe -InstallConfirm para adb install -r).'
}
