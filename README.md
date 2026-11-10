# AUTUA local-compose

Stack Docker Compose de **desenvolvimento local** (API + BFF + Postgres + auth-mock + WEB).

- Build a partir dos clones irmãos (`../autua-api`, `../autua-bff`, `../autua-web-frontend`)
- Volume dedicado `autua_local_compose_pgdata` (não reutiliza volumes de ensaio/GD-48)
- Auth-mock OIDC (`--profile auth-mock`) com usuário sintético `local-ok`
- **APP** fora do Compose — ver `scripts/android.ps1`

Não publica em `sub` / `sub-teste`. Não executa `git checkout`/`pull`. Não remove volumes no `stop`.

## 1. Arquitetura local

```text
Browser :14200  --proxy-->  BFF :18081  -->  API :18080  -->  Postgres :5434
                 \-------->  auth-mock :18082 (login / JWKS)
APP (adb reverse :8081→18081) ---------->  BFF PUBLIC_BASE (urlConsumo QR)
```

Pins validados no E2E RC1 (referência): API `a079891a` · BFF `9a2009a` · WEB `09d676c` · APP `84a4b088` + COR-QR.

## 2. Pré-requisitos

- Windows 11 + Docker Desktop
- JDK/Maven (build imagens API/BFF)
- Node/npm (WEB host)
- Opcional: FVM/Flutter + Android SDK/ADB
- Clones nas pastas irmãs (caminhos relativos — sem path absoluto de máquina)

## 3. Estrutura esperada

```text
serpro/
  autua-api/
  autua-bff/
  autua-web-frontend/
  autua-app/
  autua-local-compose/     ← este repositório/pasta
```

## 4. Clonagem

Clone os quatro projetos AUTUA na pasta pai. Use os commits/branches acordados pelo time (RC1).  
**APP:** a política de QR HTTP (`ENV=local`, hosts loopback) precisa estar **no clone compartilhado** — working tree dirty local não é entrega.

## 5. Configuração `.env`

```powershell
cd autua-local-compose
Copy-Item .env.example .env
# editar POSTGRES_PASSWORD, DATASOURCE_PASSWORD, AUTUA_PG_BACKUP_PATH (se restore)
```

Portas recomendadas no example: `18080` / `18081` / `14200` / `5434` / `18082`.

## 6. Build dos serviços

```powershell
.\scripts\01-git-status.ps1
.\scripts\02-build.ps1
docker compose --env-file .env --profile auth-mock build auth-mock
```

## 7. Inicialização

```powershell
.\scripts\doctor.ps1
$env:AUTUA_LOCAL_START_AUTHORIZED = '1'
.\scripts\start.ps1
# alternativo legado: AUTUA_PHASE_B_AUTHORIZED=1 → scripts\03-up.ps1 -AuthMock
```

`start` / `03-up` **não** executam restore nem seed.

## 8. Banco de dados

1. Volume novo → restore sanitizado **manual** (`docs/restore.md`) — dump **fora** do Git.  
2. Fixture Enrollment (`local-ok` / órgão 919001):

```powershell
.\scripts\seed-minimo.ps1 -Authorized
```

Somente `10-seed-institucional-sintetico.sql` (idempotente). Seeds 30/31 são opcionais e **explícitos**.

## 9. Auth-mock

Ver `docs/auth-mock.md`. Rebuild após mudanças em `docker/auth-mock/server.py`.

## 10. WEB

**Não** edite permanentemente `environment.ts` do tip.

```powershell
.\scripts\web-start.ps1
# http://127.0.0.1:14200 — overlay + proxy → :18081
# Ctrl+C restaura tip; ou .\scripts\web-stop.ps1
```

Detalhes: `docs/web-local.md`.

## 11–12. APP Android + ADB reverse

```powershell
.\scripts\android.ps1
# build com ENV=local e BFF_URL http://127.0.0.1:8081/autua-bff/
# install: .\scripts\android.ps1 -InstallConfirm
```

QR **HTTP** permitido apenas em APK **debug** com `ENV=local` e hosts locais autorizados (política no AUTUA-APP).

## 13. Enrollment + QR

1. WEB autenticado auth-mock `local-ok`  
2. Gestão de Dispositivos → **Gerar QR code** (`quantidadeMaxima`, aa)  
3. APP lê QR (`urlConsumo` em `127.0.0.1:18081` via reverse)  
4. Não use GD-48

## 14. Diagnóstico

| Script | Função |
|--------|--------|
| `doctor.ps1` | Pré-requisitos / clones / compose config |
| `verify.ps1` | Health HTTP não destrutivo |
| `04-status.ps1` / `05-logs.ps1` / `08-smoke.ps1` | Legados |

## 15. Troubleshooting

| Sintoma | Ação |
|---------|------|
| WEB chama `:8080` | Usar `web-start.ps1` (não tip cru) |
| Enrollment 403 scope | Rebuild auth-mock; confirmar scopes DI no token |
| Enrollment 500 gestor/órgão | `seed-minimo.ps1 -Authorized` |
| CORS `:14200` | `.env` `AUTUA_BFF_CORS_ALLOWED_ORIGINS` inclui 14200; recriar BFF se mudou env |
| QR HTTPS fail no APP | Clone sem COR-QR ou `ENV≠local` |
| Portas ocupadas | Remap no `.env` |

## 16. Limitações

- Dump sanitizado e chaves mock **não** vão no Git.  
- Imagem WEB Compose (`npm ci`) pode falhar no Windows — preferir host `web-start`.  
- Contador `quantidade_consumida` pode permanecer 0 no **reuso** de dispositivo (ver auditoria J03.4).  
- GD-48 / ensaios TLS **fora** do fluxo oficial.  
- Shareable completo exige APP com COR-QR versionado + dump obtido por canal interno.

## Documentação adicional

- `docs/ajustes-e2e-inventario.md` — inventário J01–J03  
- `docs/checklist-novo-dev.md`  
- `docs/implementation-report.md`  
- `docs/restore.md` · `docs/rebuild.md` · `docs/isolation.md`
