-- Verificações pós-seed (somente leitura). Sem PII corporativo.

\echo === destino ===
SELECT current_database() AS db, current_user AS usr, inet_server_addr() AS addr, inet_server_port() AS port;

\echo === flyway ensaio ===
SELECT COUNT(*) AS flyway_rows, MAX(version) AS tip
FROM boat_relacional.flyway_schema_history_boat;

\echo === instituicao sintetica ===
SELECT inst_id_instituicao, inst_cnpj, inst_sigla, inst_ativo, inst_excl_logica
FROM radar_relacional.tb_instituicao
WHERE inst_id_instituicao = 919001 OR inst_sigla = 'E2E_B33_ORG';

\echo === orgao sintetico ===
SELECT inst_id_instituicao, org_cod_orgao, org_esfera_administrativa, org_tipo_orgao
FROM radar_relacional.tb_orgao
WHERE inst_id_instituicao = 919001;

\echo === unidade sintetica ===
SELECT unaut_id_unidade_autuadora, unaut_cod_unidade, unaut_dsc_unidade, unaut_id_orgao, unaut_ativo, unaut_excl_logica
FROM radar_relacional.tb_unidade_autuadora
WHERE unaut_id_unidade_autuadora = 91910;

\echo === usuario sintetico (cpf mascarado) ===
SELECT usu_id_usuario,
       left(usu_num_cpf,3)||'****'||right(usu_num_cpf,2) AS cpf_mask,
       usu_num_matricula,
       usu_id_instituicao,
       usu_id_unidade_autuadora,
       usu_situacao
FROM radar_relacional.tb_usuario
WHERE usu_id_usuario = 919001 OR usu_num_matricula = 'E2E_B33_MAT';

\echo === resolucao CNPJ 14 digitos (mock) ===
SELECT COUNT(*) AS cnpj_match
FROM radar_relacional.tb_instituicao
WHERE inst_cnpj = '00000000000191' AND inst_excl_logica = FALSE;

\echo === grants autua_app ===
SELECT has_schema_privilege('autua_app','radar_relacional','USAGE') AS schema_usage,
       has_table_privilege('autua_app','radar_relacional.tb_instituicao','SELECT') AS inst_sel,
       has_table_privilege('autua_app','radar_relacional.tb_orgao','SELECT') AS orgao_sel,
       has_table_privilege('autua_app','radar_relacional.tb_unidade_autuadora','SELECT') AS ua_sel,
       has_table_privilege('autua_app','radar_relacional.tb_usuario','SELECT') AS usu_sel;
