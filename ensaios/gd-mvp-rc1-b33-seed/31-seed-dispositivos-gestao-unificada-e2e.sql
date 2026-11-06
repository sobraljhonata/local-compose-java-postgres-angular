-- MVP-WEB-07 — seed listagem unificada (5 INSTITUCIONAL + 5 PARTICULAR).
-- Somente PG ensaio (gd-mvp-rc1-flyway-ensaio / autua_local). NÃO rodar no PG principal.
-- Marcadores: E2E_B33_DI_* (institucional) · E2E_B33_DP_* (particular/IMEI) · órgão/usuário 919001.
-- Idempotente. Sem ALTER/DROP/TRUNCATE. Sem migrations.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_instituicao
    WHERE inst_id_instituicao = 919001 AND inst_sigla = 'E2E_B33_ORG'
  ) THEN
    RAISE EXCEPTION 'Pré-condição falhou: órgão sintético 919001/E2E_B33_ORG ausente';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_orgao WHERE inst_id_instituicao = 919001
  ) THEN
    RAISE EXCEPTION 'Pré-condição falhou: radar_relacional.tb_orgao 919001 ausente';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_usuario WHERE usu_id_usuario = 919001
  ) THEN
    RAISE EXCEPTION 'Pré-condição falhou: usuário sintético 919001 ausente';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- INSTITUCIONAIS (boat_relacional) — reusa 001/002 e completa até 005
-- ---------------------------------------------------------------------------

-- Alinha DI_002 ao cenário de menu AGUARDANDO_AUTORIZACAO (seed 30 original)
UPDATE boat_relacional.tb_dispositivo_institucional
SET dpin_situacao = 'AGUARDANDO_AUTORIZACAO',
    dpin_ativacao_automatica = TRUE,
    dpin_descricao = 'Seed MVP-WEB-07 DI_002 AGUARDANDO_AUTORIZACAO'
WHERE dpin_identificador = 'E2E_B33_DI_002'
  AND dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO';

INSERT INTO boat_relacional.tb_dispositivo_institucional (
  dpin_tipo_identificador, dpin_identificador, dpin_cadastro, dpin_situacao,
  dpin_ativacao_automatica, dpin_usuario_criacao_id, dpin_fabricante, dpin_modelo, dpin_descricao
)
SELECT 'IDENTIFICADOR_DISPOSITIVO', 'E2E_B33_DI_001', TRUE, 'ATIVADO', FALSE, 919001,
       'E2E_FAB_A', 'E2E_MOD_A', 'Seed MVP-WEB-07 DI_001 ATIVADO'
WHERE NOT EXISTS (
  SELECT 1 FROM boat_relacional.tb_dispositivo_institucional
  WHERE dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO' AND dpin_identificador = 'E2E_B33_DI_001'
);

INSERT INTO boat_relacional.tb_dispositivo_institucional (
  dpin_tipo_identificador, dpin_identificador, dpin_cadastro, dpin_situacao,
  dpin_ativacao_automatica, dpin_usuario_criacao_id, dpin_fabricante, dpin_modelo, dpin_descricao
)
SELECT 'IDENTIFICADOR_DISPOSITIVO', 'E2E_B33_DI_002', TRUE, 'AGUARDANDO_AUTORIZACAO', TRUE, 919001,
       'E2E_FAB_B', 'E2E_MOD_B', 'Seed MVP-WEB-07 DI_002 AGUARDANDO_AUTORIZACAO'
WHERE NOT EXISTS (
  SELECT 1 FROM boat_relacional.tb_dispositivo_institucional
  WHERE dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO' AND dpin_identificador = 'E2E_B33_DI_002'
);

INSERT INTO boat_relacional.tb_dispositivo_institucional (
  dpin_tipo_identificador, dpin_identificador, dpin_cadastro, dpin_situacao,
  dpin_ativacao_automatica, dpin_usuario_criacao_id, dpin_fabricante, dpin_modelo, dpin_descricao
)
SELECT 'IDENTIFICADOR_DISPOSITIVO', 'E2E_B33_DI_003', TRUE, 'AGUARDANDO_ATIVACAO', FALSE, 919001,
       'E2E_FAB_C', 'E2E_MOD_C', 'Seed MVP-WEB-07 DI_003 AGUARDANDO_ATIVACAO'
WHERE NOT EXISTS (
  SELECT 1 FROM boat_relacional.tb_dispositivo_institucional
  WHERE dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO' AND dpin_identificador = 'E2E_B33_DI_003'
);

INSERT INTO boat_relacional.tb_dispositivo_institucional (
  dpin_tipo_identificador, dpin_identificador, dpin_cadastro, dpin_situacao,
  dpin_ativacao_automatica, dpin_usuario_criacao_id, dpin_fabricante, dpin_modelo, dpin_descricao
)
SELECT 'IDENTIFICADOR_DISPOSITIVO', 'E2E_B33_DI_004', TRUE, 'DESATIVADO', FALSE, 919001,
       'E2E_FAB_D', 'E2E_MOD_D', 'Seed MVP-WEB-07 DI_004 DESATIVADO'
WHERE NOT EXISTS (
  SELECT 1 FROM boat_relacional.tb_dispositivo_institucional
  WHERE dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO' AND dpin_identificador = 'E2E_B33_DI_004'
);

INSERT INTO boat_relacional.tb_dispositivo_institucional (
  dpin_tipo_identificador, dpin_identificador, dpin_cadastro, dpin_situacao,
  dpin_ativacao_automatica, dpin_usuario_criacao_id, dpin_fabricante, dpin_modelo, dpin_descricao
)
SELECT 'IDENTIFICADOR_DISPOSITIVO', 'E2E_B33_DI_005', TRUE, 'NAO_AUTORIZADO', FALSE, 919001,
       'E2E_FAB_E', 'E2E_MOD_E', 'Seed MVP-WEB-07 DI_005 NAO_AUTORIZADO'
WHERE NOT EXISTS (
  SELECT 1 FROM boat_relacional.tb_dispositivo_institucional
  WHERE dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO' AND dpin_identificador = 'E2E_B33_DI_005'
);

INSERT INTO boat_relacional.tb_dispositivo_institucional_orgao (
  dpio_id_dispositivo_institucional, dpio_id_orgao, dpio_usuario_criacao_id
)
SELECT d.dpin_id, 919001, 919001
FROM boat_relacional.tb_dispositivo_institucional d
WHERE d.dpin_identificador LIKE 'E2E_B33_DI_%'
  AND NOT EXISTS (
    SELECT 1 FROM boat_relacional.tb_dispositivo_institucional_orgao o
    WHERE o.dpio_id_dispositivo_institucional = d.dpin_id AND o.dpio_id_orgao = 919001
  );

-- Visibilidade: ativação órgão <> DESATIVADO (mesmo para DI DESATIVADO/NAO_AUTORIZADO)
INSERT INTO boat_relacional.tb_dispositivo_institucional_orgao_ativacao (
  dpoa_id_dispositivo_institucional, dpoa_id_orgao, dpoa_situacao, dpoa_usuario_criacao_id
)
SELECT d.dpin_id, 919001, 'ATIVADO', 919001
FROM boat_relacional.tb_dispositivo_institucional d
WHERE d.dpin_identificador LIKE 'E2E_B33_DI_%'
  AND NOT EXISTS (
    SELECT 1 FROM boat_relacional.tb_dispositivo_institucional_orgao_ativacao a
    WHERE a.dpoa_id_dispositivo_institucional = d.dpin_id AND a.dpoa_id_orgao = 919001
  );

-- ---------------------------------------------------------------------------
-- PARTICULARES (radar_relacional.tb_dispositivo) — orgao 919001, agente 919001
-- Situações legado: 0 AUTORIZACAO · 1 ATIVACAO · 2 ATIVADO · 3 DESATIVADO
-- ---------------------------------------------------------------------------

INSERT INTO radar_relacional.tb_dispositivo (
  disp_dth_cadastro, disp_descricao, disp_imei, disp_nro_linha, disp_situacao,
  disp_id_agente, disp_id_orgao, disp_id_usuario_cadastro, disp_fabricante, disp_modelo, disp_obs
)
SELECT NOW(), 'E2E particular AG. AUTORIZAÇÃO', 'E2E_B33_DP_001', '5511900000001', 0,
       919001, 919001, 919001, 'E2E_PFAB_A', 'E2E_PMOD_A', 'Seed MVP-WEB-07 particular'
WHERE NOT EXISTS (
  SELECT 1 FROM radar_relacional.tb_dispositivo WHERE disp_imei = 'E2E_B33_DP_001'
);

INSERT INTO radar_relacional.tb_dispositivo (
  disp_dth_cadastro, disp_descricao, disp_imei, disp_nro_linha, disp_situacao,
  disp_id_agente, disp_id_orgao, disp_id_usuario_cadastro, disp_fabricante, disp_modelo, disp_obs
)
SELECT NOW(), 'E2E particular AG. ATIVAÇÃO', 'E2E_B33_DP_002', '5511900000002', 1,
       919001, 919001, 919001, 'E2E_PFAB_B', 'E2E_PMOD_B', 'Seed MVP-WEB-07 particular'
WHERE NOT EXISTS (
  SELECT 1 FROM radar_relacional.tb_dispositivo WHERE disp_imei = 'E2E_B33_DP_002'
);

INSERT INTO radar_relacional.tb_dispositivo (
  disp_dth_cadastro, disp_descricao, disp_imei, disp_nro_linha, disp_situacao,
  disp_id_agente, disp_id_orgao, disp_id_usuario_cadastro, disp_fabricante, disp_modelo, disp_obs
)
SELECT NOW(), 'E2E particular ATIVADO', 'E2E_B33_DP_003', '5511900000003', 2,
       919001, 919001, 919001, 'E2E_PFAB_C', 'E2E_PMOD_C', 'Seed MVP-WEB-07 particular'
WHERE NOT EXISTS (
  SELECT 1 FROM radar_relacional.tb_dispositivo WHERE disp_imei = 'E2E_B33_DP_003'
);

INSERT INTO radar_relacional.tb_dispositivo (
  disp_dth_cadastro, disp_descricao, disp_imei, disp_nro_linha, disp_situacao,
  disp_id_agente, disp_id_orgao, disp_id_usuario_cadastro, disp_fabricante, disp_modelo, disp_obs
)
SELECT NOW(), 'E2E particular DESATIVADO', 'E2E_B33_DP_004', '5511900000004', 3,
       919001, 919001, 919001, 'E2E_PFAB_D', 'E2E_PMOD_D', 'Seed MVP-WEB-07 particular'
WHERE NOT EXISTS (
  SELECT 1 FROM radar_relacional.tb_dispositivo WHERE disp_imei = 'E2E_B33_DP_004'
);

INSERT INTO radar_relacional.tb_dispositivo (
  disp_dth_cadastro, disp_descricao, disp_imei, disp_nro_linha, disp_situacao,
  disp_id_agente, disp_id_orgao, disp_id_usuario_cadastro, disp_fabricante, disp_modelo, disp_obs
)
SELECT NOW(), 'E2E particular AG. AUTORIZAÇÃO B', 'E2E_B33_DP_005', '5511900000005', 0,
       919001, 919001, 919001, 'E2E_PFAB_E', 'E2E_PMOD_E', 'Seed MVP-WEB-07 particular'
WHERE NOT EXISTS (
  SELECT 1 FROM radar_relacional.tb_dispositivo WHERE disp_imei = 'E2E_B33_DP_005'
);

COMMIT;

-- Verificação (somente leitura)
SELECT 'INST' AS tipo, d.dpin_identificador AS id, d.dpin_situacao AS situacao,
       d.dpin_ativacao_automatica::text AS aa
FROM boat_relacional.tb_dispositivo_institucional d
WHERE d.dpin_identificador LIKE 'E2E_B33_DI_%'
UNION ALL
SELECT 'PART', p.disp_imei, p.disp_situacao::text, NULL
FROM radar_relacional.tb_dispositivo p
WHERE p.disp_imei LIKE 'E2E_B33_DP_%'
ORDER BY 1, 2;
