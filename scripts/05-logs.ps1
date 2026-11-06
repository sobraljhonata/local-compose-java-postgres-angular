#Requires -Version 5.1
param(
  [string]$Service = '',
  [int]$Tail = 200
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
if ($Service) {
  docker compose logs --tail $Tail $Service
} else {
  docker compose logs --tail $Tail
}
