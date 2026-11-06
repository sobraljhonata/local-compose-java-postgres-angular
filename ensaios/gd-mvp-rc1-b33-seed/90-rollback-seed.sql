-- Rollback LIMITADO aos registros sintéticos E2E-B33 (PG descartável).
-- Ordem: usuario → unidade → orgao → instituicao.

BEGIN;

DELETE FROM radar_relacional.tb_usuario
WHERE usu_id_usuario = 919001
   OR usu_num_matricula = 'E2E_B33_MAT';

DELETE FROM radar_relacional.tb_unidade_autuadora
WHERE unaut_id_unidade_autuadora = 91910
  AND unaut_dsc_unidade = 'E2E-B33-UNIDADE-SYNTHETIC';

DELETE FROM radar_relacional.tb_orgao
WHERE inst_id_instituicao = 919001;

DELETE FROM radar_relacional.tb_instituicao
WHERE inst_id_instituicao = 919001
  AND inst_sigla = 'E2E_B33_ORG';

COMMIT;
