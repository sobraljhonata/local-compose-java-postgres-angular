#!/bin/sh
# Restore cluster dump into temporary Postgres only. Source is read-only mount.
set -eu
LOG=/out/restore.log
ERR=/out/restore.errors.log
: > "$LOG"
: > "$ERR"
echo "START $(date -Iseconds)" | tee -a "$LOG"
echo "PG $(psql -U extract -d postgres -tAc 'SHOW server_version')" | tee -a "$LOG"

# Cluster dump may recreate roles that already exist — continue and capture errors.
# Destination is ONLY this temporary cluster.
set +e
psql -U extract -d postgres \
  --set ON_ERROR_STOP=0 \
  -v ON_ERROR_STOP=0 \
  -f /dump/source.sql \
  > /out/restore.stdout.log 2> /out/restore.stderr.log
RC=$?
set -e

echo "psql_exit=$RC" | tee -a "$LOG"
# Summarize stderr patterns (no row data)
grep -E 'ERROR:|FATAL:|PANIC:' /out/restore.stderr.log | sed 's/\t/ /g' | sort | uniq -c | sort -nr > "$ERR" || true
echo "ERROR_LINES=$(wc -l < "$ERR")" | tee -a "$LOG"
echo "END $(date -Iseconds)" | tee -a "$LOG"
exit 0
