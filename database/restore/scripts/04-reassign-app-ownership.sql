-- Transfere ownership dos schemas da API para autua_app (DDL Flyway sem SUPERUSER).
\set ON_ERROR_STOP on

ALTER SCHEMA boat_relacional OWNER TO autua_app;
ALTER SCHEMA radar_relacional OWNER TO autua_app;
ALTER SCHEMA autua OWNER TO autua_app;
ALTER SCHEMA radar_talonario_processamento_externo OWNER TO autua_app;
ALTER SCHEMA radar OWNER TO autua_app;

REASSIGN OWNED BY autua TO autua_app;

-- Garantir que o admin local ainda consegue administrar o DB
GRANT autua_app TO autua;

SELECT n.nspname, pg_catalog.pg_get_userbyid(n.nspowner) AS owner
FROM pg_namespace n
WHERE n.nspname IN (
  'boat_relacional','radar_relacional','autua',
  'radar_talonario_processamento_externo','radar'
)
ORDER BY 1;
