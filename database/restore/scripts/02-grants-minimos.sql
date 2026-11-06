-- Privilégios mínimos locais para o usuário da API (POSTGRES_USER=autua).
-- Sem SUPERUSER. Sem roles de produção (usr_radar_des / owner_radar_des).
-- Executar como superuser do container (autua é o superuser do cluster Compose local).

\set ON_ERROR_STOP on

-- Ownership local: objetos já restaurados com --no-owner passam a pertencer ao role atual.
-- Garante USAGE nos schemas da API.
GRANT USAGE, CREATE ON SCHEMA boat_relacional TO CURRENT_USER;
GRANT USAGE, CREATE ON SCHEMA radar_relacional TO CURRENT_USER;
GRANT USAGE, CREATE ON SCHEMA autua TO CURRENT_USER;
GRANT USAGE, CREATE ON SCHEMA radar_talonario_processamento_externo TO CURRENT_USER;
GRANT USAGE, CREATE ON SCHEMA radar TO CURRENT_USER;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA boat_relacional TO CURRENT_USER;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA radar_relacional TO CURRENT_USER;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA autua TO CURRENT_USER;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA radar_talonario_processamento_externo TO CURRENT_USER;

GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA boat_relacional TO CURRENT_USER;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA radar_relacional TO CURRENT_USER;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA autua TO CURRENT_USER;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA radar_talonario_processamento_externo TO CURRENT_USER;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA boat_relacional TO CURRENT_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA radar_relacional TO CURRENT_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA autua TO CURRENT_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA radar_talonario_processamento_externo TO CURRENT_USER;

ALTER DEFAULT PRIVILEGES IN SCHEMA boat_relacional
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO CURRENT_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA radar_relacional
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO CURRENT_USER;

SELECT current_user AS db_user,
       rolsuper AS is_superuser,
       rolcreaterole AS can_create_role,
       rolcreatedb AS can_create_db
FROM pg_roles WHERE rolname = current_user;

SELECT nspname
FROM pg_namespace
WHERE nspname IN (
  'boat_relacional','radar_relacional','autua',
  'radar_talonario_processamento_externo','radar'
)
ORDER BY 1;
