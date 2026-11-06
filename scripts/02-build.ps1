#Requires -Version 5.1
<#
.SYNOPSIS
  Constrói imagens a partir dos clones locais. Não faz git checkout/pull.
  Não inicia restore. Não sobe a stack.
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

if (-not (Test-Path (Join-Path $Root '.env'))) {
  Write-Warning '.env ausente — copie .env.example antes do up. Build pode seguir com defaults parciais.'
}

# Instala .dockerignore nos clones apenas se ainda não existir (não sobrescreve)
function Ensure-Dockerignore($repoRel, $sourceRel) {
  $dest = Join-Path $Root (Join-Path $repoRel '.dockerignore')
  $src = Join-Path $Root $sourceRel
  if (-not (Test-Path $dest)) {
    Copy-Item $src $dest
    Write-Host "Criado $dest (apenas ausente)"
  } else {
    Write-Host "Mantido .dockerignore existente em $dest"
  }
}
Ensure-Dockerignore '..\autua-api' 'docker\api\dockerignore'
Ensure-Dockerignore '..\autua-bff' 'docker\bff\dockerignore'

& "$PSScriptRoot\01-git-status.ps1"

$env:DOCKER_BUILDKIT = '1'
Write-Host 'Building postgres (pull) + api + bff ...'
docker compose --env-file .env.example pull postgres 2>$null
docker compose build autua-api autua-bff

Write-Host 'Build concluído (api/bff). Profiles web/auth-mock: use -RebuildWeb / profile.'
if ($args -contains '-WithAuthMock') {
  docker compose --profile auth-mock build auth-mock
}
if ($args -contains '-WithWeb') {
  docker compose --profile web build autua-web
}
if ($args -contains '-WithWebHomolog') {
  docker compose --profile web-homolog build autua-web-homolog
}
