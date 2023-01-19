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
UPDATE temp_tbl SET operacao = 590, tabela = 'sel.inscricoes', tipo = 'A', sql = '' WHERE TRUE;
*/

--COMMIT
ROLLBACK;
BEGIN;

DO $$
    DECLARE
        int_pessoa    INTEGER := 105375;
        int_fase      INTEGER := 33054;
        int_unidade   INTEGER := 4;
        int_inscricao INTEGER;
        int_sala      INTEGER;
    BEGIN

        UPDATE temp_tbl
        SET operacao = 590,
            tabela   = 'sel.inscricoes',
            tipo     = 'I',
            sql      = '';

        INSERT INTO sel.inscricoes (pessoa, localprova, label, provaemcasa, linguaestrangeira)
        VALUES (int_pessoa, 4, 'SIM1234567', TRUE, 1)
        RETURNING codigo INTO int_inscricao;

        SELECT sel.sp_sala03(int_fase, int_unidade)
        INTO int_sala;

        UPDATE temp_tbl
        SET operacao = 590,
            tabela   = 'sel.inscricoesfases',
            tipo     = 'I',
            sql      = '';

        INSERT INTO sel.inscricoesfases (inscricao, status, fase, sala)
        VALUES (int_inscricao, 1, int_fase, int_sala);
    END;
$$;


SELECT DISTINCT
       sel.inscricoesfases.codigo AS inscricaofase,
       sel.provas.codigo          AS prova,
       bas.pessoas.nome
FROM sel.provas,
     sel.vw_fasesprovas,
     sel.fases,
     sel.ocorrencias,
     sel.processosseletivos,
     sel.inscricoesfases,
     sel.inscricoes,
     bas.pessoas,
     sel.respondentesprovas
WHERE sel.vw_fasesprovas.prova = sel.provas.codigo
  AND sel.fases.codigo = sel.vw_fasesprovas.fase
  AND sel.ocorrencias.codigo = sel.fases.ocorrencia
  AND sel.processosseletivos.codigo = sel.ocorrencias.processoseletivo
  AND sel.fases.codigo = 33054
  AND sel.inscricoesfases.fase = sel.fases.codigo
  AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
  AND bas.pessoas.codigo = sel.inscricoes.pessoa
  AND sel.inscricoesfases.status = 1
  AND (sel.inscricoesfases.codigo, sel.provas.codigo) NOT IN (
                                                                 SELECT sel.respondentesprovas.inscricaofase,
                                                                        sel.respondentesprovas.prova
                                                                 FROM sel.respondentesprovas
                                                                 WHERE sel.respondentesprovas.dataehoraliberacao IS NOT NULL
                                                             );




SELECT * FROM SEL.inscricoesfases ORDER BY 1 DESC LIMIT 10;
SELECT * FROM SEL.provas ORDER BY 1 DESC LIMIT 10;

SELECT *
FROM ava.provasonline
WHERE pessoa = 105375
ORDER BY 1 DESC
LIMIT 10;

SELECT *
FROM sis.emailbatch
ORDER BY 1 DESC
LIMIT 10;


CREATE OR REPLACE FUNCTION ava.sp_trig_liberacao_de_prova_email_insert() RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
DECLARE
    var_template RECORD;
    var_aluno    RECORD;
    var_curso    TEXT;

BEGIN
    IF new.tipo IN (1, 2) THEN
        SELECT *
        FROM com.comunicacoes
        WHERE codigo = 22
        INTO var_template;

        SELECT bas.pessoas.nome,
               bas.sp_email(bas.pessoas.codigo) AS email
        FROM bas.pessoas
        WHERE bas.pessoas.codigo = new.pessoa
        INTO var_aluno;

        SELECT COALESCE(gra.habilitacoes.nomesite, gra.habilitacoes.descricao) AS curso
        FROM ava.provasonline,
             sel.respondentesprovas,
             sel.inscricoesfases,
             sel.opcoesinscricao,
             sel.objetivos,
             gra.estruturas,
             gra.habilitacoes
        WHERE ava.provasonline.codigo = new.codigo
          AND sel.respondentesprovas.codigo = ava.provasonline.valorcampo
          AND sel.inscricoesfases.codigo = sel.respondentesprovas.inscricaofase
          AND sel.opcoesinscricao.inscricao = sel.inscricoesfases.inscricao
          AND sel.opcoesinscricao.tipoopcao = 1
          AND sel.objetivos.codigo = sel.opcoesinscricao.objetivo
          AND gra.estruturas.codigo = sel.objetivos.valorparametro3
          AND gra.habilitacoes.codigo = gra.estruturas.habilitacao
        INTO var_curso;

        var_template.corpo = replace(var_template.corpo, '[NOME]', var_aluno.nome);
        var_template.corpo = replace(var_template.corpo, '[CURSO]', COALESCE(var_curso, ''));
        var_template.corpo = replace(var_template.corpo, '[LINK]',
                                     'https://vestagendado.unisuam.edu.br/escolha-cpf-auth?token=' || new.token);

        INSERT INTO sis.emailbatch (destinatario, assunto, mensagem, dataregistro, prioridade)
        VALUES (var_aluno.email, var_template.titulo, var_template.corpo, now(), 9999);
    END IF;

    RETURN new;
END;
$$;
