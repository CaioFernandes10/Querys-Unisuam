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
UPDATE temp_tbl SET operacao = 590, tabela = 'pos.estruturasdetalhes', tipo = 'A', sql = '' WHERE TRUE;
*/

--COMMIT
ROLLBACK;
BEGIN;

SELECT pos.matriculas.aluno,
       (SELECT pos.sp_matricula_manual(pos.matriculas.aluno))
FROM pos.turmas,
     pos.matriculas
WHERE pos.matriculas.status = 1
  AND pos.turmas.codigo = pos.matriculas.turma
  AND pos.turmas.unidade_unid IN (132, 157) -- Jatiuca / PratiEnsino
  AND pos.matriculas.codigo = (
                                  SELECT codigo1
                                  FROM pos.sp_matricula04(pos.matriculas.aluno)
                              );



