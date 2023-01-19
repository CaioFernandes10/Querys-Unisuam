/*
DELETE FROM tmp_inscricoes_simulado_enem;
DROP TABLE IF EXISTS tmp_inscricoes_simulado_enem
CREATE TABLE tmp_inscricoes_simulado_enem (
    str_nome VARCHAR,
    str_email VARCHAR,
    str_cpf VARCHAR
);

ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN nome VARCHAR;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN email VARCHAR;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN cpf VARCHAR;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN cpf_valido BOOLEAN;

ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN documento_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN pessoa_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN pessoa_provisoria_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN inscricao_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN inscricao_fase_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN inscricao_provisoria_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN codigo SERIAL;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN email_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN email_provisorio_id INTEGER;
ALTER TABLE tmp_inscricoes_simulado_enem ADD COLUMN possui_email_id BOOLEAN;

*/


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
*/

--COMMIT
ROLLBACK;
BEGIN;

UPDATE tmp_inscricoes_simulado_enem
SET nome         = NULL,
    email        = NULL,
    cpf          = NULL,
    cpf_valido   = NULL,
    documento_id = NULL,
    pessoa_id    = NULL
WHERE TRUE;

UPDATE tmp_inscricoes_simulado_enem
SET nome  = LOWER(TRIM(str_nome)),
    email = LOWER(TRIM(str_email)),
    cpf   = LPAD(REGEXP_REPLACE(str_cpf, '[^[:digit:]]', '', 'g'), 11, '0')
WHERE TRUE;

UPDATE tmp_inscricoes_simulado_enem
SET cpf_valido = NOT (
                         SELECT erro
                         FROM bas.sp_validaparametrodocumento01(cpf)
                     )
WHERE TRUE;

UPDATE tmp_inscricoes_simulado_enem
SET cpf_valido = FALSE
WHERE cpf = '00000000000';

--SELECT * FROM tmp_inscricoes_simulado_enem WHERE cpf_valido = FALSE;

SELECT *
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE;

--------------------------------------------------------------------------------
UPDATE tmp_inscricoes_simulado_enem
SET documento_id = bas.documentos.codigo
FROM bas.documentos
WHERE cpf_valido = TRUE
  AND REGEXP_REPLACE(bas.documentos.campotexto1, '[^[:digit:]]', '', 'g') = tmp_inscricoes_simulado_enem.cpf;
--------------------------------------------------------------------------------
UPDATE tmp_inscricoes_simulado_enem
SET pessoa_id = bas.pessoas_documentos.pessoa
FROM bas.pessoas_documentos
WHERE bas.pessoas_documentos.documento = tmp_inscricoes_simulado_enem.documento_id;
--------------------------------------------------------------------------------

INSERT INTO bas.documentos (tipo, campotexto1)
SELECT 1, cpf
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND documento_id IS NULL;

UPDATE tmp_inscricoes_simulado_enem
SET pessoa_provisoria_id = NEXTVAL('bas.seq_pessoas')
WHERE cpf_valido = TRUE
  AND pessoa_id IS NULL
  AND pessoa_provisoria_id IS NULL;

INSERT INTO bas.pessoas (codigo, nome, nomesimples)
SELECT pessoa_provisoria_id, SUBSTRING(nome, 1, 60), UPPER(TO_ASCII(SUBSTRING(nome, 1, 60), 'LATIN1'))
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND pessoa_id IS NULL;

INSERT INTO bas.pessoas_documentos (documento, pessoa)
SELECT documento_id, pessoa_provisoria_id
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND pessoa_id IS NULL;

--------------------------------------------------------------------------------
UPDATE tmp_inscricoes_simulado_enem
SET email_id = bas.emails.codigo
FROM bas.emails
WHERE cpf_valido = TRUE
  AND TRIM(bas.emails.endereco) = tmp_inscricoes_simulado_enem.email;
--------------------------------------------------------------------------------

INSERT INTO bas.emails (tipo, endereco, confidencial, divulgacao, enviarsenha)
SELECT 1, email, FALSE, FALSE, TRUE
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND email_id IS NULL;

INSERT INTO bas.pessoas_emails (email, pessoa)
SELECT email_id, pessoa_id
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND (pessoa_id, email_id) NOT IN (
                                       SELECT pessoa, email
                                       FROM bas.pessoas_emails
                                   )
  AND email_id NOT IN (
                      SELECT email
                      FROM bas.pessoas_emails
                  );

SELECT *
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE;


--------------------------------------------------------------------------------
UPDATE tmp_inscricoes_simulado_enem
SET inscricao_id      = sel.inscricoes.codigo,
    inscricao_fase_id = sel.inscricoesfases.codigo
FROM sel.inscricoes,
     sel.inscricoesfases
WHERE tmp_inscricoes_simulado_enem.cpf_valido = TRUE
  AND sel.inscricoes.pessoa = tmp_inscricoes_simulado_enem.pessoa_id
  AND sel.inscricoesfases.inscricao = sel.inscricoes.codigo
  AND sel.inscricoesfases.fase = 33241;
--------------------------------------------------------------------------------

UPDATE tmp_inscricoes_simulado_enem
SET inscricao_provisoria_id = NEXTVAL('sel.seq_inscricoes')
WHERE cpf_valido = TRUE
  AND inscricao_id IS NULL
  AND inscricao_provisoria_id IS NULL;

--SELECT * FROM sel.processosseletivos ORDER BY 1 DESC LIMIT 10; --263
--SELECT * FROM sel.ocorrencias WHERE processoseletivo = 263; --33416
--SELECT * FROM sel.fases WHERE ocorrencia = 33416; --33237

--UPDATE temp_tbl SET operacao = 590, tabela = 'sel.inscricoes', tipo = 'I', sql = '' WHERE TRUE;
INSERT INTO sel.inscricoes (codigo, pessoa, provaemcasa, linguaestrangeira, localprova, label)
SELECT inscricao_provisoria_id, pessoa_id, TRUE, 1, 4, 'E' || LPAD(inscricao_provisoria_id, 6, '0')
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND inscricao_id IS NULL;

--UPDATE temp_tbl SET operacao = 590, tabela = 'sel.inscricoesfases', tipo = 'I', sql = '' WHERE TRUE;
INSERT INTO sel.inscricoesfases (inscricao, status, fase, sala)
SELECT inscricao_provisoria_id, 1, 33241, sel.sp_sala03(33241, 4)
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND inscricao_id IS NULL;


SELECT *
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE;



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
UPDATE temp_tbl SET operacao = 590, tabela = 'sel.provas', tipo = 'A', sql = '' WHERE TRUE;
*/

--COMMIT
ROLLBACK;
BEGIN;

SELECT *
FROM sel.sp_apura_resultado_individual(273256);

SELECT *
FROM sel.respostas
WHERE inscricaofase = 273256;

SELECT *
FROM sel.respondentesprovas
WHERE inscricaofase = 273256;

SELECT *
FROM sel.resultadosdisciplinas
WHERE inscricaofase = 273256;



SELECT *
FROM ava.questionarios_respondentes
ORDER BY 1 DESC
LIMIT 10;


SELECT sel.inscricoesfases.inscricao,
       COUNT(DISTINCT sel.respostas.codigo) FILTER ( WHERE sel.disciplinas.label = 'CHT') AS CHT,
       COUNT(DISTINCT sel.respostas.codigo) FILTER ( WHERE sel.disciplinas.label = 'CHT') AS CNT,
       COUNT(DISTINCT sel.respostas.codigo) FILTER ( WHERE sel.disciplinas.label = 'LCT') AS LCT,
       COUNT(DISTINCT sel.respostas.codigo) FILTER ( WHERE sel.disciplinas.label = 'MT')  AS MT
FROM sel.inscricoesfases
JOIN sel.respostas ON sel.respostas.inscricaofase = sel.inscricoesfases.codigo
JOIN sel.questoesprovas ON sel.questoesprovas.codigo = sel.respostas.questaoprova
JOIN ava.alternativas ON ava.alternativas.codigo = sel.respostas.alternativa
JOIN sel.configuracoesdisciplinas ON sel.configuracoesdisciplinas.codigo = sel.questoesprovas.configuracaodisciplina
JOIN sel.disciplinas ON sel.disciplinas.codigo = sel.configuracoesdisciplinas.disciplina
WHERE sel.inscricoesfases.fase = 33237
  AND ava.alternativas.gabarito IS NOT NULL
  AND sel.questoesprovas.anulada = FALSE
GROUP BY 1;



UPDATE tmp_inscricoes_simulado_enem
SET email_id = bas.pessoas_emails.email
FROM bas.pessoas_emails
WHERE cpf_valido = TRUE
  AND bas.pessoas_emails.pessoa = tmp_inscricoes_simulado_enem.pessoa_id;


SELECT *
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND email_id IS NULL;

UPDATE tmp_inscricoes_simulado_enem
SET email_provisorio_id = NEXTVAL('bas.seq_emails')
WHERE cpf_valido = TRUE
  AND email_id IS NULL
  AND email_provisorio_id IS NULL;

INSERT INTO bas.emails (codigo, tipo, endereco, divulgacao, enviarsenha)
SELECT email_provisorio_id, 1, email, TRUE, TRUE
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND email_id IS NULL;

INSERT INTO bas.pessoas_emails(email, pessoa, principal)
SELECT email_provisorio_id, pessoa_id, TRUE
FROM tmp_inscricoes_simulado_enem
WHERE cpf_valido = TRUE
  AND email_id IS NULL;



alter table bas.pessoas_emails
	add constraint uk_pessoas_emails_email
		unique (email);



alter table bas.pessoas_emails
	DROP constraint uk_pessoas_emails_email;



