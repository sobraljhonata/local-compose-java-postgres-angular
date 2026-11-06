#!/bin/sh
set -eu
pg_restore -l /dump/reduced.dump | grep -v 'MATERIALIZED VIEW radar_relacional perdas_jan_2024' | grep -v 'VIEW radar_relacional vw_auto_ecarta_expedicao_na' > /out/restore.list
wc -l /out/restore.list
grep -n 'perdas_jan_2024\|vw_auto_ecarta_expedicao_na' /out/restore.list || echo NONE
