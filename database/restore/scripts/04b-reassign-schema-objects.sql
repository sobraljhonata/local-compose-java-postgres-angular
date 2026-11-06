-- Ownership seletiva dos objetos dos schemas da API → autua_app
-- (REASSIGN OWNED completo falha: autua é role bootstrap do cluster)
\set ON_ERROR_STOP on

DO $$
DECLARE
  r record;
  kind text;
BEGIN
  FOR r IN
    SELECT n.nspname, c.relname, c.relkind
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname IN (
            'boat_relacional', 'radar_relacional', 'autua',
            'radar_talonario_processamento_externo', 'radar'
          )
      AND c.relkind IN ('r', 'p', 'v', 'm', 'S', 'i')
      AND NOT c.relispartition
  LOOP
    kind := CASE r.relkind
      WHEN 'S' THEN 'SEQUENCE'
      WHEN 'v' THEN 'VIEW'
      WHEN 'm' THEN 'MATERIALIZED VIEW'
      WHEN 'i' THEN NULL  -- index ownership follows table
      ELSE 'TABLE'
    END;
    IF kind IS NULL THEN
      CONTINUE;
    END IF;
    BEGIN
      EXECUTE format('ALTER %s %I.%I OWNER TO autua_app', kind, r.nspname, r.relname);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'skip %.%: %', r.nspname, r.relname, SQLERRM;
    END;
  END LOOP;

  FOR r IN
    SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN (
            'boat_relacional', 'radar_relacional', 'autua',
            'radar_talonario_processamento_externo', 'radar'
          )
  LOOP
    BEGIN
      EXECUTE format('ALTER FUNCTION %I.%I(%s) OWNER TO autua_app', r.nspname, r.proname, r.args);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'skip fn %.%: %', r.nspname, r.proname, SQLERRM;
    END;
  END LOOP;

  FOR r IN
    SELECT n.nspname, t.typname
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname IN ('boat_relacional', 'radar_relacional', 'autua',
                        'radar_talonario_processamento_externo', 'radar')
      AND t.typtype IN ('e', 'c', 'd')
      AND NOT EXISTS (
        SELECT 1 FROM pg_class c WHERE c.oid = t.typrelid AND c.relkind = 'c'
      )
  LOOP
    BEGIN
      EXECUTE format('ALTER TYPE %I.%I OWNER TO autua_app', r.nspname, r.typname);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'skip type %.%: %', r.nspname, r.typname, SQLERRM;
    END;
  END LOOP;
END $$;

-- Sample ownership
SELECT n.nspname||'.'||c.relname AS obj,
       pg_catalog.pg_get_userbyid(c.relowner) AS owner
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE (n.nspname, c.relname) IN (
  ('boat_relacional','tb_dispositivo_institucional'),
  ('boat_relacional','flyway_schema_history_boat'),
  ('radar_relacional','tb_dispositivo'),
  ('radar_relacional','tb_faixa_numeracao_dispositivo')
)
ORDER BY 1;
