# Relatório de implementação — consolidação local-compose

**Data:** 2026-11-06  
**Escopo:** tornar `autua-local-compose` reutilizável pós J01–J03  
**Stack E2E:** **não** interrompida · Enrollment J03 **não** re-consumido · sem commit/push

---

## Gate

**`LOCAL_COMPOSE_PARTIALLY_SHAREABLE`**

Reproduzível a partir de clones + `.env` + scripts **desde que**:

1. Dump sanitizado seja obtido por canal interno (`docs/restore.md`).  
2. Clone **APP** já contenha COR-QR (HTTP local) versionado — a alteração local dirty **não** é entrega.  
3. Auth-mock seja **rebuildado** a partir de `docker/auth-mock` (não depender de `docker cp` de ensaio).

Com essas dependências externas, o procedimento Compose/WEB/seed/android está documentado e validado parcialmente nesta máquina.

---

## Arquivos criados

| Arquivo | Motivo |
|---------|--------|
| `config/web/environment.local-compose.ts` | Overlay WEB sem tip permanente |
| `config/web/proxy.local-compose.conf.js` | Proxy → BFF/API locais |
| `scripts/web-start.ps1` / `web-stop.ps1` | Aplicar/restaurar overlay + ng serve |
| `scripts/doctor.ps1` | Pré-flight |
| `scripts/start.ps1` / `stop.ps1` | Up/stop sem restore/`-v` |
| `scripts/verify.ps1` | Smoke HTTP |
| `scripts/android.ps1` | ADB reverse + comando build |
| `scripts/seed-minimo.ps1` | Seed 10 explícito |
| `docs/web-local.md` | Desenho WEB |
| `docs/ajustes-e2e-inventario.md` | Inventário J01–J03 |
| `docs/checklist-novo-dev.md` | Onboarding |
| `docs/implementation-report.md` | Este relatório |

## Arquivos alterados

| Arquivo | Justificativa |
|---------|---------------|
| `README.md` | Guia completo equipe |
| `.env.example` | Portas remapeadas, CORS 14200, auth-mock, PUBLIC_BASE 18081 |
| `compose.yaml` | `LOCAL_ORGAO_ID=919001`, CORS defaults +14200 |
| `docs/auth-mock.md` | Scopes DI + rebuild + seed |
| `.gitignore` | `.runtime/`, `_tmp-*/` |

## Não alterados (propositadamente)

- Código de negócio API/BFF/WEB/APP  
- Volume/`postgres` em execução  
- Seeds 30/31 · restore · GD-48  
- `_tmp-j03-web-bridge` (legado de ensaio; não é o caminho oficial)

---

## Comandos executados (validação)

```text
docker compose --env-file .env config --quiet     → exit 0
.\scripts\doctor.ps1                              → OK clones/tools/compose
.\scripts\verify.ps1                              → api/bff/auth/web 200
scan segredos/sub                                 → só comentários + CHANGE_ME placeholders
scan paths absolutos em scripts/config            → 0
```

Stack observada saudável: postgres, api, bff, auth-mock; WEB host `:14200` respondendo.

---

## Limitações / riscos

| Item | Risco |
|------|-------|
| Dump sanitizado fora do Git | Onboarding bloqueado sem artefato interno |
| COR-QR só local no APP | Outro dev sem o patch falha no QR HTTP |
| Imagem auth-mock stale | Token sem DI scopes → 403 Enrollment |
| `web-start` muta tip temporariamente | Se kill -9, tip pode ficar dirty → `web-stop.ps1` |
| Contador enrollment no reuso | `quantidade_consumida` pode permanecer 0 (produto) |
| Profile `web` Compose no Windows | `npm ci` frágil — preferir host |

---

## Pendências de decisão

1. Versionar COR-QR no tip/branch APP compartilhado.  
2. Canal oficial de distribuição do dump B.2 (tamanho/licença).  
3. Se `LOCAL_ORGAO_ID` default 919001 exige recreate do auth-mock na stack atual (não feito nesta consolidação).  
4. Product: incrementar `quantidade_consumida` no path `reutilizar`.

---

## Relacionado (J03.4)

Auditoria cadastro QR: `_snapshots/.../15-auditoria-pos-cadastro-qr.md` · gate `J03_CADASTRO_CONFIRMED`.
