-- B.4.4-B.3.3 Fase B — seed institucional SINTÉTICO (PG descartável somente).
-- Marcadores: sigla E2E_B33_ORG / unidade E2E-B33-UNIDADE-SYNTHETIC / matrícula E2E_B33_MAT
-- IDs fixos: inst/orgao 919001, unidade 91910, usuario 919001
-- CNPJ/CPF: alinhados ao Auth Mock local (NÃO são dados do JWT corporativo real).
-- Idempotente: ON CONFLICT / WHERE NOT EXISTS. Transacional.

BEGIN;

-- 1) Instituição (pai JOINED de Orgao)
INSERT INTO radar_relacional.tb_instituicao (
    inst_id_instituicao,
    inst_ativo,
    inst_cnpj,
    inst_dt_cricao,
    inst_dt_ult_atualizacao,
    inst_descricao,
    inst_excl_logica,
    inst_sigla,
    inst_sigla_autentikus
)
SELECT
    919001,
    TRUE,
    '00000000000191',
    NOW(),
    NOW(),
    'E2E-B33 Orgao Sintetico Local',
    FALSE,
    'E2E_B33_ORG',
    'E2E_B33'
WHERE NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_instituicao WHERE inst_id_instituicao = 919001
);

-- Se já existir pelo ID, garantir CNPJ sintético (apenas registro do seed)
UPDATE radar_relacional.tb_instituicao
SET
    inst_cnpj = '00000000000191',
    inst_ativo = TRUE,
    inst_excl_logica = FALSE,
    inst_dt_ult_atualizacao = NOW(),
    inst_descricao = 'E2E-B33 Orgao Sintetico Local',
    inst_sigla = 'E2E_B33_ORG',
    inst_sigla_autentikus = 'E2E_B33'
WHERE inst_id_instituicao = 919001
  AND inst_sigla = 'E2E_B33_ORG';

-- 2) Órgão (JOINED)
INSERT INTO radar_relacional.tb_orgao (
    inst_id_instituicao,
    org_cod_orgao,
    org_dsc_horario_atendimento,
    org_esfera_administrativa,
    org_tipo_orgao,
    org_dsc_estado,
    org_multiplo_contratos_ecartas
)
SELECT
    919001,
    999991,
    '08:00 as 18:00',
    3,
    5,
    'DF',
    FALSE
WHERE NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_orgao WHERE inst_id_instituicao = 919001
);

-- 3) Unidade autuadora (load local após GestaoUsuarios)
INSERT INTO radar_relacional.tb_unidade_autuadora (
    unaut_id_unidade_autuadora,
    unaut_cod_unidade,
    unaut_dsc_unidade,
    unaut_id_orgao,
    unaut_ativo,
    unaut_dt_cricao,
    unaut_dt_ult_atualizacao,
    unaut_excl_logica
)
SELECT
    91910,
    91910,
    'E2E-B33-UNIDADE-SYNTHETIC',
    919001,
    TRUE,
    NOW(),
    NOW(),
    FALSE
WHERE NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_unidade_autuadora WHERE unaut_id_unidade_autuadora = 91910
);

UPDATE radar_relacional.tb_unidade_autuadora
SET
    unaut_id_orgao = 919001,
    unaut_ativo = TRUE,
    unaut_excl_logica = FALSE,
    unaut_dt_ult_atualizacao = NOW(),
    unaut_dsc_unidade = 'E2E-B33-UNIDADE-SYNTHETIC'
WHERE unaut_id_unidade_autuadora = 91910
  AND unaut_dsc_unidade = 'E2E-B33-UNIDADE-SYNTHETIC';

-- 4) Usuário (fallback recuperarOrgaoUsuario + consistência CPF)
INSERT INTO radar_relacional.tb_usuario (
    usu_id_usuario,
    usu_num_cpf,
    usu_num_matricula,
    usu_nome_usuario,
    usu_email,
    usu_id_instituicao,
    usu_id_unidade_autuadora,
    usu_id_orgao_autuador,
    administrador_sistema,
    usu_global,
    usu_estagiario,
    usu_situacao
)
SELECT
    919001,
    '39053344705',
    'E2E_B33_MAT',
    'Agente E2E B33 Sintetico',
    'e2e.b33.sintetico@example.local',
    919001,
    91910,
    919001,
    FALSE,
    FALSE,
    FALSE,
    1
WHERE NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_usuario WHERE usu_id_usuario = 919001
)
AND NOT EXISTS (
    SELECT 1 FROM radar_relacional.tb_usuario WHERE usu_num_cpf = '39053344705'
);

-- Avançar sequences além dos IDs sintéticos
SELECT setval(
    'radar_relacional.sq_instituicao',
    GREATEST(
        (SELECT COALESCE(MAX(inst_id_instituicao), 1) FROM radar_relacional.tb_instituicao),
        (SELECT last_value FROM radar_relacional.sq_instituicao)
    )
);
SELECT setval(
    'radar_relacional.sq_unidade_autuadora',
    GREATEST(
        (SELECT COALESCE(MAX(unaut_id_unidade_autuadora), 1) FROM radar_relacional.tb_unidade_autuadora),
        (SELECT last_value FROM radar_relacional.sq_unidade_autuadora)
    )
);
SELECT setval(
    'radar_relacional.sq_usuario',
    GREATEST(
        (SELECT COALESCE(MAX(usu_id_usuario), 1) FROM radar_relacional.tb_usuario),
        (SELECT last_value FROM radar_relacional.sq_usuario)
    )
);

COMMIT;
