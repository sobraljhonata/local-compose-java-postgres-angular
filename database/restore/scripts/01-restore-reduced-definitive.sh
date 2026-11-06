#!/bin/sh
# Restore definitivo do dump reduzido no DB Compose (autua_local).
# Pré: container autua-local-postgres healthy; dump em /restore/incoming/*.dump
#     e lista filtrada em /restore/incoming/restore.list (opcional).
set -eu
DUMP=${AUTUA_RESTORE_DUMP:-/restore/incoming/autua-api-min-sanitized-20261103-165903.dump}
LIST=${AUTUA_RESTORE_LIST:-/restore/incoming/restore.list}
OUT=/restore/evidence
DB=${POSTGRES_DB:-autua_local}
USER=${POSTGRES_USER:-autua}

mkdir -p "$OUT"
: > "$OUT/definitive-restore.log"
: > "$OUT/definitive-restore.stderr.log"
LOG=$OUT/definitive-restore.log
ERR=$OUT/definitive-restore.stderr.log

echo "START $(date -Iseconds)" | tee -a "$LOG"
echo "DB=$DB USER=$USER DUMP=$DUMP" | tee -a "$LOG"
pg_restore --version | tee -a "$LOG"

psql -U "$USER" -d postgres -v ON_ERROR_STOP=1 <<SQL | tee -a "$LOG"
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
SQL

psql -U "$USER" -d "$DB" -v ON_ERROR_STOP=1 <<SQL | tee -a "$LOG"
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS unaccent;
SQL

RESTORE_ARGS="-U $USER -d $DB --no-owner --no-acl --verbose"
if [ -f "$LIST" ]; then
  echo "USING_LIST=$LIST" | tee -a "$LOG"
  RESTORE_ARGS="$RESTORE_ARGS -L $LIST"
fi

echo "RESTORE_BEGIN $(date -Iseconds)" | tee -a "$LOG"
set +e
# shellcheck disable=SC2086
pg_restore $RESTORE_ARGS "$DUMP" >>"$LOG" 2>"$ERR"
RC=$?
set -e
echo "pg_restore_exit=$RC" | tee -a "$LOG"
echo "$RC" > "$OUT/definitive-restore.exit"
ERR_LINES=$(grep -cE 'ERROR:|FATAL:' "$ERR" 2>/dev/null || true)
echo "ERROR_LINES=$ERR_LINES" | tee -a "$LOG"
grep -E 'ERROR:|FATAL:' "$ERR" > "$OUT/definitive-restore.errors.log" || true
echo "RESTORE_END $(date -Iseconds)" | tee -a "$LOG"
exit 0
