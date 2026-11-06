#Requires -Version 5.1
<#
.SYNOPSIS
  Smoke GET-only em destinos locais. Sem mutações. Sem tokens em log.
#>
$ErrorActionPreference = 'Continue'
Write-Host 'Smoke local (somente GET / health / 401 esperado sem Bearer)'

function Probe($name, $url) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8
    Write-Host ("PASS {0,-28} {1}" -f $name, $r.StatusCode)
  } catch {
    $code = 0
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    if ($code -in 200, 401, 503) {
      Write-Host ("PASS {0,-28} {1}" -f $name, $code)
    } else {
      Write-Host ("FAIL {0,-28} {1}" -f $name, $(if ($code) { $code } else { 'ERR' }))
    }
  }
}

Probe 'api-health' 'http://127.0.0.1:8080/autua-api/actuator/health'
Probe 'api-gestao' 'http://127.0.0.1:8080/autua-api/dispositivos-institucionais/gestao?page=0&size=1&tipo=TODOS'
Probe 'bff-health' 'http://127.0.0.1:8081/autua-bff/actuator/health'
Probe 'bff-gestao' 'http://127.0.0.1:8081/autua-bff/dispositivos-institucionais/gestao?page=0&size=1'
Probe 'web' 'http://127.0.0.1:4200/'
Probe 'auth-mock' 'http://127.0.0.1:18082/health'
Write-Host 'Mutáveis (autorizar/ativar/desativar/QR consumir): NÃO executados.'
