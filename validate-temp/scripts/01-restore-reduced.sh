#!/bin/sh
# Restore prova do dump reduzido (-Fc) em DB descartável.
set -eu
DUMP=/dump/reduced.dump
OUT=/out
LOG=$OUT/validate-restore.log
ERR=$OUT/validate-restore.stderr.log
DB=autua_validate

: > "$LOG"
: > "$ERR"

echo "START $(date -Iseconds)" | tee -a "$LOG"
pg_restore --version | tee -a "$LOG"

# Extensões no DB postgres (template) e criar DB alvo
psql -U validate -d postgres -v ON_ERROR_STOP=1 <<'SQL' | tee -a "$LOG"
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'autua_validate' AND pid <> pg_backend_pid();
DROP DATABASE IF EXISTS autua_validate;
CREATE DATABASE autua_validate OWNER validate ENCODING 'UTF8' LOCALE 'C' TEMPLATE template0;
SQL

psql -U validate -d "$DB" -v ON_ERROR_STOP=1 <<'SQL' | tee -a "$LOG"
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
SQL

echo "RESTORE_BEGIN $(date -Iseconds)" | tee -a "$LOG"
set +e
pg_restore -U validate -d "$DB" \
  --no-owner --no-acl --verbose \
  "$DUMP" >>"$LOG" 2>"$ERR"
RC=$?
set -e
echo "pg_restore_exit=$RC" | tee -a "$LOG"
echo "$RC" > "$OUT/validate-restore.exit"
echo "RESTORE_END $(date -Iseconds)" | tee -a "$LOG"

# Contagem de erros SQL relevantes (ignora NOTICE)
ERR_LINES=$(grep -cE 'ERROR:|FATAL:' "$ERR" 2>/dev/null || true)
echo "ERROR_LINES=$ERR_LINES" | tee -a "$LOG"
grep -E 'ERROR:|FATAL:' "$ERR" > "$OUT/validate-restore.errors.log" || true

exit 0
