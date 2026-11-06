-- Sanitização B.1 — cluster temporário apenas. Sem logar valores originais.
\set ON_ERROR_STOP on
BEGIN;

-- Truncates de alto volume / PII (CASCADE). Ignora se tabela ausente via DO.
DO $$
DECLARE
  t text;
  tables text[] := ARRAY[
    'boat_relacional.tb_token_origem_app',
    'radar_relacional.tb_auto_infracao',
    'radar_relacional.tb_auto_arquivado',
    'radar_relacional.tb_cancelamento_ai',
    'radar_relacional.tb_correspondencia',
    'radar_relacional.tb_historico_acoes',
    'radar_relacional.tb_historico_login',
    'radar_relacional.tb_log_radar_mobile',
    'radar_relacional.tb_multa_dispositivo_arquivo',
    'radar_relacional.tb_multa_dispositivo',
    'radar_relacional.tb_remessa',
    'radar_relacional.solicitacao_cancelamento_medida_administrativa',
    'radar_relacional.medida_administrativa_midia',
    'radar_relacional.medida_administrativa_historico',
    'radar_relacional.medida_administrativa_condutor',
    'radar_relacional.medida_administrativa_condutor_adicional',
    'radar_relacional.medida_administrativa_proprietario',
    'radar_relacional.medida_administrativa_reboquista',
    'radar_relacional.medida_administrativa_patio',
    'radar_relacional.medida_administrativa_veiculo',
    'radar_relacional.medida_administrativa',
    'radar_relacional.inutilizacao_numero_medida_administrativa',
    'boat_relacional.pessoa_envolvida',
    'boat_relacional.pessoa_telefone',
    'boat_relacional.habilitacao',
    'boat_relacional.alcoolemia',
    'boat_relacional.veiculo',
    'boat_relacional.veiculo_informacao',
    'boat_relacional.veiculo_infracao',
    'boat_relacional.veiculo_carga',
    'boat_relacional.veiculo_croqui',
    'boat_relacional.peca_avaliada',
    'boat_relacional.componente_veiculo',
    'boat_relacional.boat_log',
    'boat_relacional.boat_historico_descritivo',
    'boat_relacional.boat_historico_descritivo_imagem',
    'boat_relacional.boat'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    IF to_regclass(t) IS NOT NULL THEN
      EXECUTE format('TRUNCATE TABLE %s RESTART IDENTITY CASCADE', t);
      RAISE NOTICE 'truncated %', t;
    END IF;
  END LOOP;
END $$;

-- Usuários: 2 fases no CPF para evitar colisão intermediária no UNIQUE
UPDATE radar_relacional.tb_usuario u SET
  usu_num_cpf = 'Z' || lpad((u.usu_id_usuario % 10000000000)::text, 10, '0'),
  usu_nome_usuario = 'Usuario Sintetico ' || u.usu_id_usuario::text,
  usu_email = 'user' || u.usu_id_usuario::text || '@example.local',
  usu_telefone = NULL,
  usu_num_matricula = 'MAT' || u.usu_id_usuario::text,
  usu_senha = NULL;
UPDATE radar_relacional.tb_usuario u SET
  usu_num_cpf = lpad((u.usu_id_usuario % 100000000000)::text, 11, '0');

-- Instituições: limpar contato se colunas existirem
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='radar_relacional' AND table_name='tb_instituicao' AND column_name='inst_telefone'
  ) THEN
    EXECUTE $q$UPDATE radar_relacional.tb_instituicao SET inst_telefone = NULL$q$;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='radar_relacional' AND table_name='tb_instituicao' AND column_name='inst_email'
  ) THEN
    EXECUTE $q$UPDATE radar_relacional.tb_instituicao SET inst_email = 'org' || inst_id_instituicao::text || '@example.local'$q$;
  END IF;
END $$;

-- Passagem dinâmica em tabelas base (não views)
DO $$
DECLARE
  r record;
  sql text;
BEGIN
  FOR r IN
    SELECT c.table_schema, c.table_name, c.column_name, c.data_type,
           COALESCE(c.character_maximum_length, 255) AS maxlen
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema=c.table_schema AND t.table_name=c.table_name
    WHERE c.table_schema IN ('boat_relacional', 'radar_relacional', 'autua', 'radar_talonario_processamento_externo')
      AND t.table_type = 'BASE TABLE'
      AND (
        c.column_name ~* '(cpf|cnpj|email|e_mail|telefone|celular|senha|password|passwd|token|secret|matricula|endereco|logradouro|bairro|cep|nome_mae|nome_pai)'
        OR c.column_name ~* '(nome_usuario|nome_condutor|nome_proprietario|possuidor_nome|habilitado_nome)'
      )
      -- já tratado explicitamente
      AND NOT (c.table_schema='radar_relacional' AND c.table_name='tb_usuario')
    ORDER BY 1,2,3
  LOOP
    BEGIN
      IF r.column_name ~* '(senha|password|passwd|token|secret)' THEN
        sql := format('UPDATE %I.%I SET %I = NULL WHERE %I IS NOT NULL', r.table_schema, r.table_name, r.column_name, r.column_name);
      ELSIF r.data_type IN ('character varying', 'character', 'text') THEN
        sql := format(
          'UPDATE %I.%I SET %I = left(%L || md5(COALESCE(%I::text, '''')), %s) WHERE %I IS NOT NULL',
          r.table_schema, r.table_name, r.column_name,
          'SYN_', r.column_name,
          GREATEST(LEAST(r.maxlen, 255), 1),
          r.column_name
        );
      ELSE
        CONTINUE;
      END IF;
      EXECUTE sql;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'skip %.%.% (%)', r.table_schema, r.table_name, r.column_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- Talão externo + autua: truncar dados
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT schemaname, tablename FROM pg_tables
           WHERE schemaname IN ('radar_talonario_processamento_externo', 'autua')
  LOOP
    EXECUTE format('TRUNCATE TABLE %I.%I RESTART IDENTITY CASCADE', r.schemaname, r.tablename);
  END LOOP;
END $$;

COMMIT;

-- Validação: nenhum e-mail fora de example.local / SYN_ em usuarios
SELECT count(*) AS usuarios,
       count(*) FILTER (WHERE usu_email IS NOT NULL AND usu_email NOT LIKE '%@example.local') AS email_nao_sintetico,
       count(*) FILTER (WHERE usu_senha IS NOT NULL) AS senha_preenchida
FROM radar_relacional.tb_usuario;

SELECT count(*) AS dispositivos FROM radar_relacional.tb_dispositivo;
SELECT count(*) AS flyway FROM boat_relacional.flyway_schema_history_boat;
SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;
