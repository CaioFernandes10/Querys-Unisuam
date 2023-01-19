DROP TABLE IF EXISTS tmp_relatorio_aluno_protocolo;
CREATE TABLE tmp_relatorio_aluno_protocolo
(
    matricula                VARCHAR,
    data_colacao             VARCHAR,
    pessoa_id                INTEGER,
    aluno_id                 INTEGER,
    historico_id             INTEGER,
    matricula_id             INTEGER,
    possivel_formando        BOOLEAN,
    pro_protocolos_codigo    INTEGER,
    pro_requerimentos_codigo INTEGER,
    pro_departamento_codigo  INTEGER
);

INSERT INTO tmp_relatorio_aluno_protocolo (matricula, pessoa_id, aluno_id, historico_id, matricula_id)
SELECT gra.alunos.label,
       bas.pessoas.codigo,
       gra.alunos.codigo,
       gra.historicos.codigo,
       gra.matriculas.codigo
FROM gra.matriculas,
     gra.periodosletivos,
     gra.historicos,
     gra.inscricoes,
     gra.alunos,
     bas.pessoas
WHERE gra.matriculas.status = 1
  AND gra.periodosletivos.codigo = gra.matriculas.periodoletivo
  AND gra.periodosletivos.label = '2022-1'
  AND gra.historicos.codigo = gra.matriculas.historico
  AND gra.inscricoes.codigo = gra.historicos.inscricao
  AND gra.alunos.codigo = gra.inscricoes.aluno
  AND bas.pessoas.codigo = gra.alunos.pessoa;

UPDATE tmp_relatorio_aluno_protocolo
SET possivel_formando = FALSE
FROM pro.protocolos,
     pro.requerimentos,
     pro.encaminhamentos
WHERE pro.protocolos.pessoa = tmp_relatorio_aluno_protocolo.pessoa_id
  AND pro.requerimentos.protocolo = pro.protocolos.codigo
  AND pro.requerimentos.tiporequerimento = 1101
  AND pro.encaminhamentos.requerimento = pro.requerimentos.codigo
  AND pro.encaminhamentos.status != 4
  AND pro.encaminhamentos.codigo = (
                                       SELECT MAX(codigo)
                                       FROM pro.encaminhamentos encaminhamentos
                                       WHERE encaminhamentos.requerimento = pro.requerimentos.codigo
                                   );

DELETE
FROM tmp_relatorio_aluno_protocolo
WHERE possivel_formando = FALSE;

UPDATE tmp_relatorio_aluno_protocolo
SET possivel_formando = gra.sp_possivelformando(historico_id)
WHERE possivel_formando IS NULL;

DELETE
FROM tmp_relatorio_aluno_protocolo
WHERE possivel_formando = FALSE;

SELECT possivel_formando, COUNT(*)
FROM tmp_relatorio_aluno_protocolo
GROUP BY 1;

--ALTER TABLE tmp_relatorio_aluno_protocolo ADD COLUMN matricula_id INTEGER;
--UPDATE tmp_relatorio_aluno_protocolo SET matricula_id = gra.sp_aluno02_2(aluno_id, '2022-1');

--protocolo-possiveis-formandos
SELECT bas.pessoas.nome                    AS nome,
       gra.alunos.label                    AS matricula,
       gra.formasdeingressoaluno.descricao AS formaingresso,
       bas.unidades.nomecurto              AS unidade,
       gra.cursos.nome                     AS curso,
       gra.modalidadescurso.descricao      AS modalidade,
       gra.habilitacoes.descricao          AS habilitacao,
       gra.estruturas.label                AS estrutura,
       gra.formatoestrutura.descricao      AS formato,
       gra.turnos.descricao                AS turno
FROM bas.pessoas
JOIN gra.alunos ON gra.alunos.pessoa = bas.pessoas.codigo
JOIN gra.inscricoes ON gra.inscricoes.aluno = gra.alunos.codigo
JOIN gra.historicos ON gra.historicos.inscricao = gra.inscricoes.codigo
JOIN gra.matriculas ON gra.matriculas.historico = gra.historicos.codigo
JOIN gra.estruturas ON gra.estruturas.codigo = gra.historicos.estrutura
JOIN gra.habilitacoes ON gra.habilitacoes.codigo = gra.estruturas.habilitacao
JOIN gra.cursos ON gra.cursos.codigo = gra.habilitacoes.curso
JOIN gra.formatoestrutura ON gra.formatoestrutura.codigo = gra.estruturas.formato
JOIN gra.modalidadescurso ON gra.modalidadescurso.codigo = gra.cursos.modalidade
JOIN bas.unidades ON bas.unidades.codigo = gra.matriculas.unidade_unid
JOIN gra.turnos ON gra.turnos.codigo = gra.matriculas.turno
JOIN gra.periodosletivos ON gra.periodosletivos.codigo = gra.matriculas.periodoletivo
JOIN gra.formasdeingressoaluno ON gra.formasdeingressoaluno.codigo = gra.alunos.formadeingresso
JOIN tmp_relatorio_aluno_protocolo ON tmp_relatorio_aluno_protocolo.matricula_id = gra.matriculas.codigo
ORDER BY 1, 2, 3, 4, 5, 7, 8;




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
UPDATE temp_tbl SET operacao = 590, tabela = 'gra.matriculas', tipo = 'A', sql = '' WHERE TRUE;
*/

--COMMIT
ROLLBACK;
BEGIN;

UPDATE tmp_relatorio_aluno_protocolo
SET pro_protocolos_codigo = (
                                SELECT pro.sp_incluiprotocolo(1,
                                                              NULL,
                                                              tmp_relatorio_aluno_protocolo.aluno_id,
                                                              TRUE)
                            )
WHERE pro_protocolos_codigo IS NULL;

UPDATE tmp_relatorio_aluno_protocolo
SET pro_requerimentos_codigo = (
                                   SELECT pro.sp_incluirequerimento(1101,
                                                                    pro_protocolos_codigo,
                                                                    'Protocolo Aberto para análise documental do aluno após encerramento do registro acadêmico',
                                                                    1,
                                                                    1)
                               )
WHERE pro_requerimentos_codigo IS NULL;
