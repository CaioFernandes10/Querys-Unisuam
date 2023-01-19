DROP TABLE IF EXISTS tmp_protocolos_cancelar;
CREATE TEMPORARY TABLE tmp_protocolos_cancelar AS
SELECT pro.protocolos.matricula,
       pro.requerimentos.tiporequerimento,
       ARRAY_AGG(pro.requerimentos.codigo ORDER BY pro.requerimentos.codigo)  AS requerimento,
       ARRAY_AGG(DISTINCT pro.statusencaminhamento.descricaosimples::VARCHAR) AS status
FROM pro.protocolos,
     pro.requerimentos,
     pro.tiposrequerimento,
     pro.encaminhamentos,
     pro.statusencaminhamento
WHERE TRUE
  --AND pro.protocolos.matricula = '16200292'
  AND pro.requerimentos.protocolo = pro.protocolos.codigo
  AND pro.tiposrequerimento.codigo = pro.requerimentos.tiporequerimento
  AND pro.tiposrequerimento.label IN ('B09', 'C01', 'B06')
  AND pro.encaminhamentos.requerimento = pro.requerimentos.codigo
  AND pro.statusencaminhamento.codigo = pro.encaminhamentos.status
  AND pro.protocolos.dataprotocolo = '21/03/2022'
  AND pro.encaminhamentos.status != 4
  AND pro.encaminhamentos.codigo = (
                                       SELECT MAX(codigo)
                                       FROM pro.encaminhamentos
                                       WHERE requerimento = pro.requerimentos.codigo
                                   )
GROUP BY 1, 2
HAVING COUNT(*) > 1;

SELECT * FROM tmp_protocolos_cancelar;

/*
ROLLBACK;
DROP TABLE IF EXISTS temp_tbl;
CREATE TEMPORARY TABLE temp_tbl (
  usuario INTEGER, programa INTEGER, ipinterno VARCHAR, ipexterno VARCHAR,
  tabela VARCHAR, operacao INTEGER, tipo VARCHAR, sql VARCHAR,
  valorparametro1 INTEGER, valorparametro2 INTEGER, valorparametro3 INTEGER,
  valorparametro4 INTEGER, valorparametro5 INTEGER, valorparametro6 INTEGER
);
DELETE FROM temp_tbl WHERE TRUE;
INSERT INTO temp_tbl (usuario, programa, ipinterno, ipexterno) VALUES (5, 8, '', '');
UPDATE temp_tbl SET operacao = 590, tabela = 'pro.encaminhamentos', tipo = 'I', sql = '' WHERE TRUE;
*/


--COMMIT
ROLLBACK;
BEGIN;

INSERT INTO pro.encaminhamentos (status, requerimento, usuario, parecerinterno, parecerexterno, departamento)
SELECT 4, requerimento, 5, 'PROTOCOLO CANCELADO', 'PROTOCOLO CANCELADO', departamento
FROM pro.encaminhamentos
WHERE requerimento IN (
                          SELECT UNNEST(ARRAY_REMOVE(requerimento, requerimento[1]))
                          FROM tmp_protocolos_cancelar
                      )
  AND codigo = (
                   SELECT MAX(codigo)
                   FROM pro.encaminhamentos enc
                   WHERE enc.requerimento = pro.encaminhamentos.requerimento
               );