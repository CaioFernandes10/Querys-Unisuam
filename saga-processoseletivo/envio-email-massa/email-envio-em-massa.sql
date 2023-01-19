/*
--identificados codigos para processamento
SELECT DISTINCT
       sel.ocorrencias.codigo    AS ocorrencia_id,
       sel.ocorrencias.descricao AS ocorrencia,
       sel.fases.codigo          AS fase_id,
       sel.fases.status          AS status_id,
       sel.provas.codigo         AS prova_id,
       sel.provas.questionario
FROM sel.ocorrencias,
     sel.fases,
     sel.fasesobjetivosprovas,
     sel.provas
WHERE sel.ocorrencias.tipo = 4
  AND sel.fases.ocorrencia = sel.ocorrencias.codigo
  AND sel.fasesobjetivosprovas.fase = sel.fases.codigo
  AND sel.provas.codigo = sel.fasesobjetivosprovas.prova
  AND sel.provas.objetiva = FALSE
ORDER BY 1 DESC;
*/

--COMMIT
ROLLBACK;
BEGIN;

DO
$$
    DECLARE
        rec_pessoas            RECORD;
        rec_comunicacao        RECORD;
        var_email_destinatario VARCHAR;
        var_email_titulo       VARCHAR;
        var_email_corpo        VARCHAR;
        int_comunicacao        INTEGER := 55;
        int_fase               INTEGER := 40059;
        int_prioridade         INTEGER := 9999;
    BEGIN

        SELECT titulo, corpo, codigo
        FROM com.comunicacoes
        WHERE codigo = int_comunicacao
        INTO rec_comunicacao;

        FOR rec_pessoas IN
            SELECT SPLIT_PART(bas.pessoas.nome, ' ', 1) AS nome,
                   bas.sp_email(bas.pessoas.codigo)     AS email,
                   bas.unidades.nomesite                AS unidade,
                   COALESCE(gra.habilitacoes.nomesite, gra.habilitacoes.descricao) ||
                   CASE
                       WHEN gra.modalidadescurso.codigo = 2
                           THEN ' (' || gra.modalidadescurso.descricao || ')'
                       ELSE '' END                      AS habilitacao,
                   gra.turnos.descricao                 AS turno,
                   bas.salas.label || bas.blocos.label  AS sala
            FROM sel.inscricoesfases,
                 sel.inscricoes,
                 sel.opcoesinscricao,
                 sel.objetivos,
                 bas.unidades,
                 gra.estruturas,
                 gra.habilitacoes,
                 gra.cursos,
                 gra.modalidadescurso,
                 gra.turnos,
                 bas.pessoas,
                 bas.salas,
                 bas.blocos
            WHERE sel.inscricoesfases.fase = int_fase
              AND sel.inscricoesfases.status != 9
              AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
              AND sel.opcoesinscricao.inscricao = sel.inscricoes.codigo
              AND sel.opcoesinscricao.tipoopcao = 1
              AND sel.objetivos.codigo = sel.opcoesinscricao.objetivo
              AND bas.unidades.codigo = sel.objetivos.valorparametro1
              AND gra.estruturas.codigo = sel.objetivos.valorparametro3
              AND gra.habilitacoes.codigo = gra.estruturas.habilitacao
              AND gra.cursos.codigo = gra.habilitacoes.curso
              AND gra.modalidadescurso.codigo = gra.cursos.modalidade
              AND gra.turnos.codigo = sel.objetivos.valorparametro4
              AND bas.pessoas.codigo = sel.inscricoes.pessoa
              AND bas.salas.codigo = sel.inscricoesfases.sala
              AND bas.blocos.codigo = bas.salas.bloco
            ORDER BY RANDOM()
            --LIMIT 5
        LOOP

            var_email_destinatario := rec_pessoas.email;
            var_email_titulo := 'Confira seu comprovante de inscrição do Vestibular Solidário!!';
            var_email_corpo := rec_comunicacao.corpo;

            var_email_corpo := REPLACE(var_email_corpo, '[NOME]', rec_pessoas.nome);
            var_email_corpo := REPLACE(var_email_corpo, '[SALA]', rec_pessoas.sala);
            var_email_corpo := REPLACE(var_email_corpo, '[CURSO]', rec_pessoas.habilitacao);
            var_email_corpo := REPLACE(var_email_corpo, '[TURNO]', rec_pessoas.turno);
            var_email_corpo := REPLACE(var_email_corpo, '[UNIDADE]', rec_pessoas.unidade);

            --var_email_destinatario := 'joaorca@unisuam.edu.br';

            IF (var_email_destinatario IS NULL) THEN CONTINUE; END IF;

            INSERT INTO sis.emailbatch (destinatario, assunto, mensagem, prioridade)
            VALUES (var_email_destinatario, var_email_titulo, var_email_corpo, int_prioridade);

        END LOOP;
    END
$$;

SELECT codigo, destinatario, dataregistro, dataenviado, prioridade
FROM sis.emailbatch
WHERE TRUE
  --AND dataenviado IS NOT NULL
  AND codigo > 11847068
  AND assunto = 'Confira seu comprovante de inscrição do Vestibular Solidário!!'
ORDER BY dataregistro;

--SELECT MAX(codigo) FROM sis.emailbatch;

SELECT dataenviado IS NOT NULL AS enviado,
       COUNT(*)                AS qntd
FROM sis.emailbatch
WHERE codigo > 11847068
  AND assunto = 'Confira seu comprovante de inscrição do Vestibular Solidário!!'
GROUP BY 1;


--quantidade de emails nao enviados
SELECT COUNT(*)
FROM sis.emailbatch
WHERE dataenviado IS NULL;

--ultimos emails enviado
SELECT codigo, destinatario, assunto, dataregistro, dataenviado, prioridade
FROM sis.emailbatch
WHERE dataenviado IS NOT NULL
ORDER BY dataenviado DESC
LIMIT 10;

--quantidade de emails enviados por hora
SELECT TO_CHAR(dataenviado, 'yyyy-mm-dd hh24'), COUNT(*)
FROM sis.emailbatch
WHERE dataenviado IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC
LIMIT 240;

--quantidade de emails nao enviados por assunto
SELECT prioridade, assunto, COUNT(*)
FROM sis.emailbatch
WHERE dataenviado IS NULL
GROUP BY 1, 2
ORDER BY 1 DESC;
