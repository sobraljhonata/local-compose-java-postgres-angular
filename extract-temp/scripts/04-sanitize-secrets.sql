\set ON_ERROR_STOP on
BEGIN;

UPDATE radar_relacional.tb_leiaute_contrato SET
  lecont_ecartas_senha_ftp = 'SYN_FTP_PASS',
  lecont_ecartas_usuario_ftp = COALESCE(NULLIF(lecont_ecartas_usuario_ftp, ''), 'syn_ftp_user'),
  lecont_cedo_senha_ftp = CASE WHEN lecont_cedo_senha_ftp IS NOT NULL THEN 'SYN_FTP_PASS' ELSE NULL END,
  lecont_cedo_usuario_ftp = CASE WHEN lecont_cedo_usuario_ftp IS NOT NULL THEN 'syn_ftp_user' ELSE NULL END;

UPDATE radar_relacional.tb_convenio_bancario
  SET cob_cliente_senha = NULL WHERE cob_cliente_senha IS NOT NULL;

UPDATE radar_relacional.tb_impressao_txt
  SET imp_dados_ftp = NULL WHERE imp_dados_ftp IS NOT NULL;

UPDATE radar_relacional.tb_postagem_ar_ftp
  SET caminho_ftp = 'SYN_/ftp/path' WHERE caminho_ftp IS NOT NULL;

DO $$
BEGIN
  IF to_regclass('radar_talonario_processamento_externo.tb_usuario_configuracao_ftp') IS NOT NULL THEN
    EXECUTE 'TRUNCATE TABLE radar_talonario_processamento_externo.tb_usuario_configuracao_ftp RESTART IDENTITY CASCADE';
  END IF;
  IF to_regclass('radar_talonario_processamento_externo.tb_configuracoes_webhook') IS NOT NULL THEN
    EXECUTE 'TRUNCATE TABLE radar_talonario_processamento_externo.tb_configuracoes_webhook RESTART IDENTITY CASCADE';
  END IF;
END $$;

COMMIT;

SELECT 'leiaute' AS t, count(*)::text FROM radar_relacional.tb_leiaute_contrato
UNION ALL SELECT 'convenio_senha_nn', count(*)::text FROM radar_relacional.tb_convenio_bancario WHERE cob_cliente_senha IS NOT NULL;
