-- Rollback MVP-WEB-07 — remove SOMENTE marcadores E2E_B33_DI_* e E2E_B33_DP_* no PG ensaio.
-- Ordem DI: ativação → associação → dispositivo. Particular: delete por IMEI.
-- Sem TRUNCATE/DROP. Não remove registros não marcados.

BEGIN;

DELETE FROM boat_relacional.tb_dispositivo_institucional_orgao_ativacao a
USING boat_relacional.tb_dispositivo_institucional d
WHERE a.dpoa_id_dispositivo_institucional = d.dpin_id
  AND d.dpin_identificador LIKE 'E2E_B33_DI_%';

DELETE FROM boat_relacional.tb_dispositivo_institucional_orgao o
USING boat_relacional.tb_dispositivo_institucional d
WHERE o.dpio_id_dispositivo_institucional = d.dpin_id
  AND d.dpin_identificador LIKE 'E2E_B33_DI_%';

DELETE FROM boat_relacional.tb_dispositivo_institucional
WHERE dpin_identificador LIKE 'E2E_B33_DI_%';

DELETE FROM radar_relacional.tb_dispositivo
WHERE disp_imei LIKE 'E2E_B33_DP_%';

COMMIT;

SELECT
  (SELECT COUNT(*) FROM boat_relacional.tb_dispositivo_institucional WHERE dpin_identificador LIKE 'E2E_B33_DI_%') AS di_restantes,
  (SELECT COUNT(*) FROM radar_relacional.tb_dispositivo WHERE disp_imei LIKE 'E2E_B33_DP_%') AS dp_restantes;
