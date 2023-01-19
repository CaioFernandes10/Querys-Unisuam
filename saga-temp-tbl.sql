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

/* '^([0-6]+[.]?[0-6]*|[.][0-6]+)$' */

--528 -- ANO DA TABELA DE REABERTURA
--436 -- qh do professor
--430 -- qh do aluno


SELECT * from sis.tiposparametro where label = 'gra0011';

--COMMIT
ROLLBACK;
BEGIN;

SELECT *,
       TRIM(REGEXP_REPLACE(numero, '[^[:digit:]]', '', 'g')),
       LENGTH(TRIM(REGEXP_REPLACE(numero, '[^[:digit:]]', '', 'g')))
FROM bas.telefones
WHERE TRIM(REGEXP_REPLACE(numero, '[^[:digit:]]', '', 'g')) != numero
  AND LENGTH(TRIM(REGEXP_REPLACE(numero, '[^[:digit:]]', '', 'g'))) NOT IN (7, 8, 9);



/*
SELECT gra.estruturas.label        AS estrutura,
       gra.periodos.label::INTEGER AS periodo,
       gra.competencias.ordem      AS ordem,
       gra.competencias.competencia
FROM gra.competencias,
     gra.periodos,
     gra.estruturas
WHERE gra.periodos.codigo = gra.competencias.periodo
  AND gra.estruturas.codigo = gra.periodos.estrutura
ORDER BY 1, 2, 3, 4;
*/

/*
DROP TABLE IF EXISTS tmp_bolsas_carencia;
CREATE TEMPORARY TABLE tmp_bolsas_carencia
(
    debito_id     INTEGER,
    aluno_id      INTEGER,
    valor         NUMERIC,
    matricula     VARCHAR,
    aluno         VARCHAR,
    unidade       VARCHAR,
    curso         VARCHAR,
    modalidade    VARCHAR,
    turno         VARCHAR,
    status        VARCHAR,
    conclusao     VARCHAR,
    periodoletivo VARCHAR
);

INSERT INTO tmp_bolsas_carencia (debito_id, valor)
SELECT bol.pedidos.debito,
       bol.historicospedidos.valor
FROM bol.pedidos,
     bol.historicospedidos
WHERE bol.historicospedidos.pedido = bol.pedidos.codigo
  AND bol.historicospedidos.modificador IN (10786, 1036)
  AND bol.historicospedidos.statusmotivo = 2
  AND bol.historicospedidos.codigo = (
                                         SELECT MAX(codigo)
                                         FROM bol.historicospedidos
                                         WHERE pedido = bol.pedidos.codigo
                                     );

UPDATE tmp_bolsas_carencia
SET matricula     = gra.alunos.label,
    aluno         = bas.pessoas.nome,
    unidade       = bas.unidades.nomecurto,
    curso         = gra.cursos.nome,
    modalidade    = gra.modalidadescurso.descricao,
    turno         = gra.turnos.descricao,
    periodoletivo = gra.periodosletivos.label,
    aluno_id      = gra.alunos.codigo
FROM car.debitos,
     car.devedores,
     ven.formasrecporservico,
     ven.servicos,
     bas.unidades,
     gra.periodosletivos,
     gra.cursos,
     gra.modalidadescurso,
     gra.turnos,
     gra.alunos,
     bas.pessoas
WHERE car.debitos.codigo = tmp_bolsas_carencia.debito_id
  AND car.devedores.codigo = car.debitos.devedor
  AND ven.formasrecporservico.codigo = car.debitos.formarecservico
  AND ven.servicos.codigo = ven.formasrecporservico.servico
  AND bas.unidades.codigo = ven.servicos.valorcampo1
  AND gra.periodosletivos.codigo = ven.servicos.valorcampo2
  AND gra.cursos.codigo = ven.servicos.valorcampo3
  AND gra.modalidadescurso.codigo = gra.cursos.modalidade
  AND gra.turnos.codigo = ven.servicos.valorcampo4
  AND car.devedores.tipo = 2
  AND gra.alunos.codigo = car.devedores.valorcampo
  AND bas.pessoas.codigo = gra.alunos.pessoa;


UPDATE tmp_bolsas_carencia
SET status    = gra.statusinscricoes.descricao,
    conclusao = gra.periodosletivos.label
FROM gra.inscricoes
JOIN gra.statusinscricoes ON gra.statusinscricoes.codigo = gra.inscricoes.status
LEFT JOIN gra.periodosletivos ON gra.periodosletivos.codigo = gra.inscricoes.periodoletivoconclusao
WHERE gra.inscricoes.aluno = tmp_bolsas_carencia.aluno_id
  AND gra.inscricoes.codigo = gra.sp_aluno01(gra.inscricoes.aluno);

SELECT matricula,
       aluno,
       periodoletivo,
       unidade,
       curso,
       modalidade,
       turno,
       valor,
       status,
       conclusao
FROM tmp_bolsas_carencia
ORDER BY 1, 3;
*/
