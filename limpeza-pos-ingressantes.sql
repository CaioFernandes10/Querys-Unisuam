ROLLBACK;
DROP TABLE IF EXISTS tmp_ingressantes_excluir;
CREATE TEMPORARY TABLE tmp_ingressantes_excluir AS
SELECT *
FROM pos.ingressantes
WHERE codigo NOT IN (
                        SELECT ingressante_id
                        FROM (
                                 SELECT pessoa, MAX(codigo) AS ingressante_id
                                 FROM pos.ingressantes
                                 GROUP BY 1
                             ) dados
                    )
  AND codigo NOT IN (
                        SELECT ingressante_id
                        FROM hep.fluxos
                    );


--COMMIT
ROLLBACK;
BEGIN;
ALTER TABLE pos.ingressantes
    DISABLE TRIGGER ALL;
DELETE
FROM pos.ingressantes
WHERE codigo IN (
                    SELECT codigo
                    FROM tmp_ingressantes_excluir
                    --LIMIT 100000
                );
ALTER TABLE pos.ingressantes
    ENABLE TRIGGER ALL;


SELECT COUNT(*)
FROM pos.ingressantes;


SELECT pessoa, ARRAY_AGG(codigo)
FROM pos.ingressantes
GROUP BY 1
HAVING COUNT(*) > 1
