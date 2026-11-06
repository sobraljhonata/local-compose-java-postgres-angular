-- Follow-up: tabelas backup/PII residual
\set ON_ERROR_STOP on
BEGIN;

TRUNCATE TABLE radar_relacional.tb_usuario_bkp RESTART IDENTITY CASCADE;
TRUNCATE TABLE radar_relacional.tb_usuario_tarsis RESTART IDENTITY CASCADE;
TRUNCATE TABLE radar_relacional.tb_historico_login_mobile RESTART IDENTITY CASCADE;
TRUNCATE TABLE radar_relacional.usuario_notificacao RESTART IDENTITY CASCADE;
TRUNCATE TABLE radar_relacional.tb_usuario_lote_item_erro RESTART IDENTITY CASCADE;
TRUNCATE TABLE radar_relacional.tb_usuario_lote_item RESTART IDENTITY CASCADE;
TRUNCATE TABLE radar_relacional.tb_usuario_lote RESTART IDENTITY CASCADE;

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT c.table_schema, c.table_name, c.column_name,
           COALESCE(c.character_maximum_length, 255) AS maxlen, c.data_type
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema=c.table_schema AND t.table_name=c.table_name AND t.table_type='BASE TABLE'
    WHERE c.table_schema IN ('boat_relacional','radar_relacional','autua','radar_talonario_processamento_externo')
      AND c.column_name ~* '(cpf|email|senha|password|token|telefone|matricula)'
      AND NOT (c.table_schema='radar_relacional' AND c.table_name='tb_usuario')
  LOOP
    BEGIN
      IF r.column_name ~* '(senha|password|token)' THEN
        EXECUTE format('UPDATE %I.%I SET %I = NULL WHERE %I IS NOT NULL',
          r.table_schema, r.table_name, r.column_name, r.column_name);
      ELSIF r.data_type IN ('character varying','character','text') THEN
        EXECUTE format(
          'UPDATE %I.%I SET %I = left(%L || md5(COALESCE(%I::text,'''')), %s) WHERE %I IS NOT NULL AND %I::text !~ %L',
          r.table_schema, r.table_name, r.column_name,
          'SYN_', r.column_name,
          GREATEST(LEAST(r.maxlen, 255), 1),
          r.column_name, r.column_name,
          '^(SYN_|[0-9]{11})$'
        );
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'skip %.%.%: %', r.table_schema, r.table_name, r.column_name, SQLERRM;
    END;
  END LOOP;
END $$;

COMMIT;

SELECT 'usuario_bkp' AS t, count(*)::text AS n FROM radar_relacional.tb_usuario_bkp
UNION ALL SELECT 'usuario_tarsis', count(*)::text FROM radar_relacional.tb_usuario_tarsis
UNION ALL SELECT 'hist_login_mobile', count(*)::text FROM radar_relacional.tb_historico_login_mobile
UNION ALL SELECT 'usuarios', count(*)::text FROM radar_relacional.tb_usuario
UNION ALL SELECT 'senha_nonnull', count(*)::text FROM radar_relacional.tb_usuario WHERE usu_senha IS NOT NULL
UNION ALL SELECT 'email_bad', count(*)::text FROM radar_relacional.tb_usuario WHERE usu_email IS NOT NULL AND usu_email NOT LIKE '%@example.local';
