# Estratégia de banco mínimo (B.0) — preparada, não executada

Ver relatório completo: `_snapshots/gestao-dispositivos-unificada/13-banco-minimo-autua-api.md`.

## Pré-requisito

1. Confirmar path do backup (o de **hoje** não foi encontrado em 2026-11-03).
2. Não usar dumps `…1331` / `…1429` — **truncados** (sem trailer `dump complete`).
3. Candidato íntegro mais recente local: `dump-dbdes_10197_radar_aux-202610191647.sql` (cluster, PG 17.10) — só com autorização explícita.

## Extração recomendada (após GO)

Ambiente **temporário** isolado (`postgres:17`, volume descartável, porta efêmera):

1. Restore controlado do dump autorizado (sem tocar `autua_gd_pgdata_local`).
2. `pg_dump` nativo do DB alvo com:
   - `-n boat_relacional -n radar_relacional`
   - avaliar `-n radar` se objetos legados existirem
   - `--no-owner --no-acl --no-comments` (ou comments on)
   - **não** incluir roles globais SUPERUSER
3. Sanitizar PII em staging (ver relatório §10).
4. Gerar artefato `database/restore/incoming/autua-api-minimo-YYYYMMDD.sql` (fora do Git).
5. Destruir volume temporário.

**Proibido:** cortar o SQL plain com regex.

## Compose

Importar somente o artefato reduzido no volume `autua_local_compose_pgdata` na Fase B posterior.
