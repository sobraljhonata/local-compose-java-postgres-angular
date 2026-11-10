#Requires -Version 5.1
<#
.SYNOPSIS
  Restaura environment.ts do tip WEB se o overlay local-compose estiver aplicado.
  Não encerra processos node automaticamente (encerre o ng serve com Ctrl+C).
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$WebRoot = Join-Path (Split-Path -Parent $Root) 'autua-web-frontend'
$EnvFile = Join-Path $WebRoot 'src\app\core\config\environments\environment.ts'
$Backup = Join-Path $Root 'config\web\.runtime\environment.ts.bak'

if (-not (Test-Path $Backup)) {
  Write-Host 'Nenhum backup de overlay encontrado — nada a restaurar.'
  exit 0
}
Copy-Item $Backup $EnvFile -Force
Write-Host "Restaurado: $EnvFile"
Remove-Item $Backup -Force
Write-Host 'Backup removido.'
