-- Rollback MVP-WEB-04 — remove SOMENTE marcadores E2E_B33_DI_* no PG ensaio.
-- Ordem: ativação → associação → dispositivo. Sem TRUNCATE/DROP.

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

COMMIT;

SELECT COUNT(*) AS restantes_e2e_di
FROM boat_relacional.tb_dispositivo_institucional
WHERE dpin_identificador LIKE 'E2E_B33_DI_%';
