DROP TABLE IF EXISTS tmp_alunos_mestrados;
CREATE TEMPORARY TABLE tmp_alunos_mestrados AS
SELECT mes.alunos.label  AS matricula,
       bas.pessoas.nome  AS aluno,
       mes.cursos.nome   AS curso,
       mes.turmas.label  AS turma,
       mes.alunos.codigo AS aluno_id,
       mes.turmas.codigo AS turma_id
FROM mes.matriculas,
     mes.turmas,
     mes.cursos,
     mes.alunos,
     bas.pessoas
WHERE mes.matriculas.status = 2
  AND mes.turmas.codigo = mes.matriculas.turma
  AND mes.cursos.codigo = mes.turmas.curso
  AND mes.alunos.codigo = mes.matriculas.aluno
  AND bas.pessoas.codigo = mes.alunos.pessoa
  AND mes.matriculas.codigo = (
                                  SELECT codigo1
                                  FROM mes.sp_matricula01(mes.matriculas.aluno)
                              );

ALTER TABLE tmp_alunos_mestrados
    ADD COLUMN devedor_id INTEGER;

UPDATE tmp_alunos_mestrados
SET devedor_id = car.devedores.codigo
FROM car.devedores
WHERE car.devedores.valorcampo = tmp_alunos_mestrados.aluno_id
  AND car.devedores.tipo = 6;

ALTER TABLE tmp_alunos_mestrados
    ADD COLUMN debito_id INTEGER;

UPDATE tmp_alunos_mestrados
SET debito_id = car.debitos.codigo
FROM car.debitos,
     ven.formasrecporservico,
     ven.servicos
WHERE car.debitos.devedor = tmp_alunos_mestrados.devedor_id
  AND ven.formasrecporservico.codigo = car.debitos.formarecservico
  AND ven.servicos.codigo = ven.formasrecporservico.servico
  AND ven.servicos.valorcampo1 = tmp_alunos_mestrados.turma_id;

DO
$$
    DECLARE
        rec_boletos RECORD;
    BEGIN
        FOR i IN 0..1
        LOOP
            FOR j IN 1..7
            LOOP
                EXECUTE 'ALTER TABLE tmp_alunos_mestrados ADD COLUMN bol_' || 2021 + i || LPAD(j, 2, '0') ||
                        ' VARCHAR;';
            END LOOP;
        END LOOP;

        FOR rec_boletos IN
            SELECT car.boletos.debito                                       AS debito_id,
                   TO_CHAR(car.boletos.datavencto, 'YYYYMM')                AS competencia,
                   CASE WHEN car.boletos.status = 6 THEN 'PAGO' ELSE '' END AS pago
            FROM tmp_alunos_mestrados,
                 car.boletos
            WHERE car.boletos.debito = tmp_alunos_mestrados.debito_id
              AND car.boletos.parcelaformarecebimento IS NOT NULL
              AND car.boletos.status != 7
              AND (TO_CHAR(car.boletos.datavencto, 'YYYYMM') BETWEEN '202101' AND '202107'
                OR TO_CHAR(car.boletos.datavencto, 'YYYYMM') BETWEEN '202201' AND '202207')
        LOOP
            EXECUTE 'UPDATE tmp_alunos_mestrados SET bol_' || rec_boletos.competencia ||
                    ' = ''' || rec_boletos.pago || ''' WHERE debito_id = ' || rec_boletos.debito_id;
        END LOOP;
    END
$$;

SELECT *
FROM tmp_alunos_mestrados
ORDER BY aluno;