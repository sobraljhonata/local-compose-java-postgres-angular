-- Validação pós-restore (prova) — contagens apenas
\set ON_ERROR_STOP on
\echo === INTEGRITY_START ===

SELECT version();

SELECT nspname AS schema
FROM pg_namespace
WHERE nspname IN (
  'boat_relacional','radar_relacional','autua',
  'radar_talonario_processamento_externo','radar'
)
ORDER BY 1;

SELECT
  n.nspname AS schema,
  count(*) FILTER (WHERE c.relkind = 'r') AS tables,
  count(*) FILTER (WHERE c.relkind = 'v') AS views,
  count(*) FILTER (WHERE c.relkind = 'S') AS sequences,
  count(*) FILTER (WHERE c.relkind = 'm') AS matviews
FROM pg_namespace n
LEFT JOIN pg_class c ON c.relnamespace = n.oid
WHERE n.nspname IN (
  'boat_relacional','radar_relacional','autua',
  'radar_talonario_processamento_externo','radar'
)
GROUP BY 1
ORDER BY 1;

SELECT 'fk' AS kind, count(*)::text AS n
FROM pg_constraint con
JOIN pg_namespace n ON n.oid = con.connamespace
WHERE con.contype = 'f'
  AND n.nspname IN ('boat_relacional','radar_relacional','autua','radar_talonario_processamento_externo')
UNION ALL
SELECT 'flyway_rows', count(*)::text FROM boat_relacional.flyway_schema_history_boat
UNION ALL
SELECT 'dispositivos', count(*)::text FROM radar_relacional.tb_dispositivo
UNION ALL
SELECT 'usuarios', count(*)::text FROM radar_relacional.tb_usuario
UNION ALL
SELECT 'orgaos', count(*)::text FROM radar_relacional.tb_orgao
UNION ALL
SELECT 'unidades', count(*)::text FROM radar_relacional.tb_unidade_autuadora
UNION ALL
SELECT 'auto_infracao', count(*)::text FROM radar_relacional.tb_auto_infracao
UNION ALL
SELECT 'usu_email_ok',
       (count(*) FILTER (WHERE usu_email LIKE '%@example.local' OR usu_email IS NULL) = count(*))::text
FROM radar_relacional.tb_usuario
UNION ALL
SELECT 'usu_senha_null',
       (count(*) FILTER (WHERE usu_senha IS NULL) = count(*))::text
FROM radar_relacional.tb_usuario;

-- FKs quebradas (filho sem pai) — amostra crítica
SELECT 'fk_dispositivo_usuario_ok' AS chk,
       (NOT EXISTS (
         SELECT 1
         FROM radar_relacional.tb_dispositivo d
         LEFT JOIN radar_relacional.tb_usuario u ON u.usu_id_usuario = d.disp_id_usuario_cadastro
         WHERE d.disp_id_usuario_cadastro IS NOT NULL AND u.usu_id_usuario IS NULL
       ))::text AS ok;

SELECT version, description, success, installed_rank
FROM boat_relacional.flyway_schema_history_boat
ORDER BY installed_rank;

\echo === INTEGRITY_END ===
