-- Gate B.2 / validação residual PII — apenas contagens, sem valores.
-- Executar: psql -v ON_ERROR_STOP=1 -f /scripts/05-validate-pii.sql
\set ON_ERROR_STOP on

\echo === VALIDATE_PII_START ===

DO $validate_pii$
DECLARE
  r record;
  nn bigint;
  bad bigint;
  q text;
  residual_total bigint := 0;
  secret_residual bigint := 0;
  check_fail bigint := 0;
BEGIN
  FOR r IN
    SELECT c.table_schema, c.table_name, c.column_name
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema
     AND t.table_name = c.table_name
     AND t.table_type = 'BASE TABLE'
    WHERE c.table_schema IN (
            'boat_relacional',
            'radar_relacional',
            'autua',
            'radar_talonario_processamento_externo'
          )
      AND c.column_name ~* '(cpf|email|senha|token)'
    ORDER BY 1, 2, 3
  LOOP
    q := format(
      'SELECT count(*) FROM %I.%I WHERE %I IS NOT NULL',
      r.table_schema, r.table_name, r.column_name
    );
    EXECUTE q INTO nn;
    IF nn = 0 THEN
      CONTINUE;
    END IF;

    IF r.column_name ~* 'senha|token' THEN
      q := format(
        'SELECT count(*) FROM %I.%I WHERE %I IS NOT NULL AND %I::text NOT LIKE %L AND %I::text <> %L',
        r.table_schema, r.table_name, r.column_name, r.column_name, 'SYN_%',
        r.column_name, 'SYN_FTP_PASS'
      );
      BEGIN
        EXECUTE q INTO bad;
        IF bad > 0 THEN
          secret_residual := secret_residual + bad;
          RAISE NOTICE 'SECRET_RESIDUAL %.%.% count=%', r.table_schema, r.table_name, r.column_name, bad;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        check_fail := check_fail + 1;
        RAISE NOTICE 'CHECK_FAIL %.%.%: %', r.table_schema, r.table_name, r.column_name, SQLERRM;
      END;
      CONTINUE;
    END IF;

    IF r.column_name ~* 'email' THEN
      q := format(
        'SELECT count(*) FROM %I.%I WHERE %I IS NOT NULL AND %I::text NOT LIKE %L AND %I::text NOT LIKE %L',
        r.table_schema, r.table_name, r.column_name, r.column_name, '%@example.local',
        r.column_name, 'SYN_%'
      );
    ELSE
      -- CPF: aceita SYN_ ou 11 dígitos sintéticos derivados de id
      q := format(
        'SELECT count(*) FROM %I.%I WHERE %I IS NOT NULL AND %I::text !~ %L AND %I::text NOT LIKE %L',
        r.table_schema, r.table_name, r.column_name, r.column_name, '^[0-9]{11}$',
        r.column_name, 'SYN_%'
      );
    END IF;

    BEGIN
      EXECUTE q INTO bad;
      IF bad > 0 THEN
        residual_total := residual_total + bad;
        RAISE NOTICE 'RESIDUAL %.%.% nn=% bad=%', r.table_schema, r.table_name, r.column_name, nn, bad;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      check_fail := check_fail + 1;
      RAISE NOTICE 'CHECK_FAIL %.%.%: %', r.table_schema, r.table_name, r.column_name, SQLERRM;
    END;
  END LOOP;

  RAISE NOTICE 'SUMMARY residual=% secret_residual=% check_fail=%', residual_total, secret_residual, check_fail;

  IF residual_total > 0 OR secret_residual > 0 OR check_fail > 0 THEN
    RAISE EXCEPTION 'PII_VALIDATION_FAILED residual=% secret_residual=% check_fail=%',
      residual_total, secret_residual, check_fail;
  END IF;
END
$validate_pii$;

\echo === VALIDATE_PII_DO_OK ===

SELECT 'ok_usuarios_sinteticos' AS chk,
       count(*) AS usuarios,
       count(*) FILTER (WHERE usu_email LIKE '%@example.local' OR usu_email IS NULL) = count(*) AS emails_ok,
       count(*) FILTER (WHERE usu_senha IS NULL) = count(*) AS senhas_null,
       count(*) FILTER (WHERE usu_nome_usuario LIKE 'Usuario Sintetico %') = count(*) AS nomes_ok
FROM radar_relacional.tb_usuario;

\echo === VALIDATE_PII_END ===
