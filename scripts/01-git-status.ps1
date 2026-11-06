#Requires -Version 5.1
<#
.SYNOPSIS
  Registra branch/SHA/dirty dos clones. Não executa checkout/pull/stash.
  Modo homolog: falha se dirty sem AUTUA_ALLOW_DIRTY=1.
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Evidence = Join-Path $Root 'evidence'
New-Item -ItemType Directory -Force -Path $Evidence | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $Evidence "git-status-$stamp.json"

$repos = @(
  @{ name = 'autua-api'; path = (Join-Path $Root '..\autua-api') },
  @{ name = 'autua-bff'; path = (Join-Path $Root '..\autua-bff') },
  @{ name = 'autua-web-frontend'; path = (Join-Path $Root '..\autua-web-frontend') }
)

$mode = if ($env:AUTUA_MODE) { $env:AUTUA_MODE } else { 'dev' }
$allowDirty = $env:AUTUA_ALLOW_DIRTY -eq '1'
$result = @()

foreach ($r in $repos) {
  Push-Location $r.path
  $branch = (git rev-parse --abbrev-ref HEAD).Trim()
  $sha = (git rev-parse HEAD).Trim()
  $short = (git rev-parse --short HEAD).Trim()
  $porcelain = git status --porcelain
  $dirty = @($porcelain).Count
  Pop-Location
  $entry = [ordered]@{
    name           = $r.name
    path           = (Resolve-Path $r.path).Path
    branch         = $branch
    sha            = $sha
    shaShort       = $short
    dirtyFileCount = $dirty
    dirty          = ($dirty -gt 0)
  }
  $result += $entry
  Write-Host ("{0,-22} {1,-32} {2} dirty={3}" -f $r.name, $branch, $short, $dirty)
}

$payload = [ordered]@{
  capturedAt = (Get-Date).ToString('o')
  mode       = $mode
  repos      = $result
}
$payload | ConvertTo-Json -Depth 5 | Set-Content -Path $out -Encoding UTF8
Write-Host "Evidence: $out"

if ($mode -eq 'homolog' -and -not $allowDirty) {
  $dirtyRepos = $result | Where-Object { $_.dirty }
  if ($dirtyRepos) {
    throw "Modo homolog exige working tree limpa (ou AUTUA_ALLOW_DIRTY=1). Sujos: $($dirtyRepos.name -join ', ')"
  }
}

# manifesto pins opcional
$pins = Join-Path $Root 'manifests\git-pins.json'
$pins | Out-Null
Copy-Item $out (Join-Path $Root 'manifests\git-pins.last.json') -Force
