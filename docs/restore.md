# Restore PostgreSQL — autua-local-compose

## Status

**B.2 concluída (2026-11-04):** dump reduzido sanitizado restaurado em `autua_local_compose_pgdata`  
(`autua-local-postgres` @ `127.0.0.1:5434`). Relatório:  
`_snapshots/gestao-dispositivos-unificada/15-restauracao-banco-compose.md`.  
API/BFF/WEB **não** iniciados; Flyway **não** executado (`SPRING_FLYWAY_ENABLED=false`).

B.0/B.1: ver relatórios `13-…` e `14-…` no mesmo diretório de snapshots.

## Candidatos encontrados (host) — 2026-10-19

| Arquivo | Tamanho | Tipo | Origem PG | Integridade |
|---------|---------|------|-----------|-------------|
| `…202610191331.sql` | ~1,36 GB | `pg_dump` DB `dbdes_10197_radar_aux` | **17.10** | **TRUNCADO** — não usar |
| `…202610191429.sql` | ~1,36 GB | idem | 17.10 | **TRUNCADO** — não usar |
| `…202610191633.sql` | ~2,51 GB | **cluster dump** | 17.10 | Completo |
| `…202610191647.sql` | ~2,51 GB | cluster dump | 17.10 | Completo (mais recente íntegro) |

Schemas úteis à API: `boat_relacional`, `radar_relacional` (+ condicionais `radar` / `autua` / talão externo).  
Dezenas de schemas de outros produtos Radar: **fora** do banco mínimo.  
Cluster dumps criam roles `usr_radar_des` / `owner_radar_des` (SUPERUSER) — **não** aplicar cegamente.

## Isolamento

| Item | Valor |
|------|-------|
| Volume destino | `autua_local_compose_pgdata` (**novo**) |
| **Não** reutilizar | `autua_gd_pgdata_local`, `autua-e2e-pgdata` |
| Container | `autua-local-postgres` |
| Imagem | `postgres:17-alpine` (major alinhado ao dump) |
| Bind | `127.0.0.1:5433` (ou porta alternativa no `.env`) |

## Riscos

1. **Dados pessoais / ambiente DES** — dumps de `dbdes_*` provavelmente contêm PII. Propor sanitização ou subset antes de uso amplo.
2. `DROP DATABASE` / `CREATE DATABASE` nos dumps — restore exige superuser no container e adaptação do nome do DB (`autua_local` vs `dbdes_10197_radar_aux`).
3. Flyway da API GD 2.0 pode divergir do schema do dump — validar histórico Flyway **antes** de `SPRING_FLYWAY_ENABLED=true` no primeiro boot.
4. Não executar `flyway repair|baseline|clean` automaticamente.

## Procedimento proposto (somente após autorização)

1. Usuário indica **um** caminho em `AUTUA_PG_BACKUP_PATH`.
2. Copiar dump para `database/restore/incoming/` (fora do Git).
3. `docker compose up -d postgres` com volume vazio.
4. Preparar script de restore **manual** (psql) com:
   - remoção/adaptação de `DROP DATABASE`/`CREATE DATABASE` se necessário;
   - mapeamento de roles para `POSTGRES_USER`;
   - log de evidência em `evidence/`.
5. Validar `\dn`, contagens mínimas, ausência de conexão remota.
6. Só então subir API com Flyway conforme decisão documentada.

## Rollback local

- `docker compose down` (**sem** `-v`) para parar.
- Para zerar DB Compose: somente com autorização explícita `docker volume rm autua_local_compose_pgdata`.
- Stack host (`autua-postgres-gd-local` / Java 8080/8081) permanece intocada por estes scripts.
