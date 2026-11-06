-- Role de aplicação local (B.3) — sem SUPERUSER, sem roles de produção.
\set ON_ERROR_STOP on

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'autua_app') THEN
    CREATE ROLE autua_app LOGIN PASSWORD 'autua_app_local_only' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;
  ELSE
    ALTER ROLE autua_app WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT;
    ALTER ROLE autua_app PASSWORD 'autua_app_local_only';
  END IF;
END $$;

GRANT CONNECT ON DATABASE autua_local TO autua_app;

GRANT USAGE, CREATE ON SCHEMA boat_relacional TO autua_app;
GRANT USAGE, CREATE ON SCHEMA radar_relacional TO autua_app;
GRANT USAGE, CREATE ON SCHEMA autua TO autua_app;
GRANT USAGE, CREATE ON SCHEMA radar_talonario_processamento_externo TO autua_app;
GRANT USAGE ON SCHEMA radar TO autua_app;
GRANT USAGE ON SCHEMA public TO autua_app;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA boat_relacional TO autua_app;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA radar_relacional TO autua_app;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA autua TO autua_app;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA radar_talonario_processamento_externo TO autua_app;

GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA boat_relacional TO autua_app;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA radar_relacional TO autua_app;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA autua TO autua_app;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA radar_talonario_processamento_externo TO autua_app;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA boat_relacional TO autua_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA radar_relacional TO autua_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA autua TO autua_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA radar_talonario_processamento_externo TO autua_app;

ALTER DEFAULT PRIVILEGES FOR ROLE autua IN SCHEMA boat_relacional
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO autua_app;
ALTER DEFAULT PRIVILEGES FOR ROLE autua IN SCHEMA radar_relacional
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO autua_app;
ALTER DEFAULT PRIVILEGES FOR ROLE autua IN SCHEMA boat_relacional
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO autua_app;
ALTER DEFAULT PRIVILEGES FOR ROLE autua IN SCHEMA radar_relacional
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO autua_app;

-- Flyway precisa gravar no history
GRANT SELECT, INSERT, UPDATE ON boat_relacional.flyway_schema_history_boat TO autua_app;

SELECT rolname, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles WHERE rolname IN ('autua', 'autua_app')
ORDER BY 1;
