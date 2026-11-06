# AUTUA local-compose

Stack Docker Compose de **desenvolvimento** e **homologação local**:

- AUTUA API (build do clone `../autua-api`)
- AUTUA BFF (build do clone `../autua-bff`)
- AUTUA WEB (clone `../autua-web-frontend`, profiles `web` / `web-homolog`)
- PostgreSQL 17 (volume **novo** `autua_local_compose_pgdata`)
- Auth-mock OIDC opcional (`--profile auth-mock`)

**APP fora do escopo.** Não publica em subcontratacao. Não executa git checkout/pull.

## Relação com `autua-local-e2e`

`autua-local-e2e` já existe, mas usa **JARs pré-compilados**, portas 1808x/5435 e seeds sintéticos.  
Esta pasta (`autua-local-compose`) foi criada para cumprir o requisito de **build a partir dos clones** + restore de backup + portas 8080/8081/4200/5433. O auth-mock reutiliza o contrato do identity E2E (adaptado).

## Fase A (atual)

Arquivos e scripts criados. **Sem** `compose up` de aplicação, **sem** restore.

## Fase B (aguardando autorização)

Ver `docs/phase-b-plan.md` e relatório  
`_snapshots/gestao-dispositivos-unificada/12-stack-docker-compose-local.md`.

## Quickstart (após Fase B)

```powershell
cd C:\dev\Projetos\serpro\autua-local-compose
Copy-Item .env.example .env   # editar senha + AUTUA_PG_BACKUP_PATH
.\scripts\00-prereqs.ps1
.\scripts\01-git-status.ps1
.\scripts\02-build.ps1
$env:AUTUA_PHASE_B_AUTHORIZED = '1'
.\scripts\03-up.ps1            # ainda sem restore automático
# restore manual: docs/restore.md
.\scripts\04-status.ps1
.\scripts\08-smoke.ps1
.\scripts\06-down.ps1          # nunca usa -v
```

## Portas padrão (127.0.0.1)

| Serviço | Porta |
|---------|-------|
| WEB | 4200 |
| API | 8080 |
| BFF | 8081 |
| Postgres | 5433 |
| auth-mock | 18082 |

**Conflito:** a stack host GD atual já usa 4200/8080/8081/5433. Resolver antes do up.

## WEB / browser

O bundle Angular deve continuar apontando para `http://localhost:8080|8081` (portas publicadas).  
**Não** usar hostnames `autua-api` / `autua-bff` no JavaScript do browser.

## Documentação

- `docs/restore.md` — dumps candidatos e plano de restore  
- `docs/rebuild.md` — rebuild por clone  
- `docs/isolation.md` — isolamento  
- `docs/auth-mock.md` — OIDC local  
- `docs/phase-b-plan.md` — checklist de autorização  
