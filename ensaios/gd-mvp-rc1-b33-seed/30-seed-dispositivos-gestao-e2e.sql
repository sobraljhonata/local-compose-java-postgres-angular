-- MVP-WEB-04 — seed MÍNIMO de dispositivos institucionais para listagem Gestão E2E.
-- Somente PG ensaio (gd-mvp-rc1-flyway-ensaio / autua_local). NÃO rodar no PG principal.
-- Marcadores: identificadores E2E_B33_DI_* / órgão 919001 / usuário 919001.
-- Idempotente. Sem ALTER/DROP/TRUNCATE. Sem migrations.

BEGIN;

-- Pré-condição: órgão/usuário sintéticos do script 10
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_instituicao
    WHERE inst_id_instituicao = 919001 AND inst_sigla = 'E2E_B33_ORG'
  ) THEN
    RAISE EXCEPTION 'Pré-condição falhou: órgão sintético 919001/E2E_B33_ORG ausente';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_usuario WHERE usu_id_usuario = 919001
  ) THEN
    RAISE EXCEPTION 'Pré-condição falhou: usuário sintético 919001 ausente';
  END IF;
END $$;

-- Dispositivo 1 — ATIVADO, ativação automática false (listagem padrão)
INSERT INTO boat_relacional.tb_dispositivo_institucional (
  dpin_tipo_identificador,
  dpin_identificador,
  dpin_cadastro,
  dpin_situacao,
  dpin_ativacao_automatica,
  dpin_usuario_criacao_id,
  dpin_fabricante,
  dpin_modelo,
  dpin_descricao
)
SELECT
  'IDENTIFICADOR_DISPOSITIVO',
  'E2E_B33_DI_001',
  TRUE,
  'ATIVADO',
  FALSE,
  919001,
  'E2E_FAB_A',
  'E2E_MOD_A',
  'Seed MVP-WEB-04 listagem E2E'
WHERE NOT EXISTS (
  SELECT 1 FROM boat_relacional.tb_dispositivo_institucional
  WHERE dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO'
    AND dpin_identificador = 'E2E_B33_DI_001'
);

-- Dispositivo 2 — AGUARDANDO_AUTORIZACAO, ativação automática true (filtros)
INSERT INTO boat_relacional.tb_dispositivo_institucional (
  dpin_tipo_identificador,
  dpin_identificador,
  dpin_cadastro,
  dpin_situacao,
  dpin_ativacao_automatica,
  dpin_usuario_criacao_id,
  dpin_fabricante,
  dpin_modelo,
  dpin_descricao
)
SELECT
  'IDENTIFICADOR_DISPOSITIVO',
  'E2E_B33_DI_002',
  TRUE,
  'AGUARDANDO_AUTORIZACAO',
  TRUE,
  919001,
  'E2E_FAB_B',
  'E2E_MOD_B',
  'Seed MVP-WEB-04 filtros E2E'
WHERE NOT EXISTS (
  SELECT 1 FROM boat_relacional.tb_dispositivo_institucional
  WHERE dpin_tipo_identificador = 'IDENTIFICADOR_DISPOSITIVO'
    AND dpin_identificador = 'E2E_B33_DI_002'
);

-- Associação N:N com órgão 919001
INSERT INTO boat_relacional.tb_dispositivo_institucional_orgao (
  dpio_id_dispositivo_institucional,
  dpio_id_orgao,
  dpio_usuario_criacao_id
)
SELECT d.dpin_id, 919001, 919001
FROM boat_relacional.tb_dispositivo_institucional d
WHERE d.dpin_identificador IN ('E2E_B33_DI_001', 'E2E_B33_DI_002')
  AND NOT EXISTS (
    SELECT 1 FROM boat_relacional.tb_dispositivo_institucional_orgao o
    WHERE o.dpio_id_dispositivo_institucional = d.dpin_id
      AND o.dpio_id_orgao = 919001
  );

-- Ativação de órgão (visível na listagem se <> DESATIVADO)
INSERT INTO boat_relacional.tb_dispositivo_institucional_orgao_ativacao (
  dpoa_id_dispositivo_institucional,
  dpoa_id_orgao,
  dpoa_situacao,
  dpoa_usuario_criacao_id
)
SELECT d.dpin_id, 919001, 'ATIVADO', 919001
FROM boat_relacional.tb_dispositivo_institucional d
WHERE d.dpin_identificador IN ('E2E_B33_DI_001', 'E2E_B33_DI_002')
  AND NOT EXISTS (
    SELECT 1 FROM boat_relacional.tb_dispositivo_institucional_orgao_ativacao a
    WHERE a.dpoa_id_dispositivo_institucional = d.dpin_id
      AND a.dpoa_id_orgao = 919001
  );

COMMIT;

-- Verificação (somente leitura)
SELECT d.dpin_id, d.dpin_identificador, d.dpin_situacao, d.dpin_ativacao_automatica,
       a.dpoa_id_orgao, a.dpoa_situacao AS ativacao_orgao
FROM boat_relacional.tb_dispositivo_institucional d
JOIN boat_relacional.tb_dispositivo_institucional_orgao_ativacao a
  ON a.dpoa_id_dispositivo_institucional = d.dpin_id
WHERE d.dpin_identificador LIKE 'E2E_B33_DI_%'
ORDER BY d.dpin_identificador;
