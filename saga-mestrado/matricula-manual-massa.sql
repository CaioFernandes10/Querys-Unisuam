/*
DROP TABLE IF EXISTS tmp_matricula_manual;
CREATE TABLE tmp_matricula_manual (matricula VARCHAR);
DELETE FROM tmp_matricula_manual WHERE TRUE;
UPDATE tmp_matricula_manual SET matricula = LPAD(matricula,8,'0');
SELECT * FROM tmp_matricula_manual;
*/

/*
INSERT INTO tmp_matricula_manual (matricula)
VALUES ('MACR00404');
*/

DROP TABLE IF EXISTS tmp_processo_manual;
CREATE TEMPORARY TABLE tmp_processo_manual AS
SELECT mes.alunos.label,
       mes.matriculas.codigo AS matricula_id,
       mes.matriculas.status
FROM tmp_matricula_manual,
     mes.alunos,
     mes.matriculas
WHERE mes.alunos.label = tmp_matricula_manual.matricula
  AND mes.matriculas.aluno = mes.alunos.codigo
  AND mes.matriculas.status = 1
  AND mes.matriculas.codigo = (
                                  SELECT codigo1
                                  FROM mes.sp_matricula01(mes.alunos.codigo)
                              );

SELECT * FROM tmp_processo_manual;
