SELECT candidato,
       cpf,
       celular,
       email,
       'https://vestagendado.unisuam.edu.br/escolha-cpf-auth?token=' || token_objetiva AS objetiva,
       'https://vestagendado.unisuam.edu.br/escolha-cpf-auth?token=' || token_redacao  AS redacao
FROM (
         SELECT bas.pessoas.nome                      AS candidato
              , bas.sp_cpf(sel.inscricoes.pessoa)     AS cpf
              , bas.sp_celular(sel.inscricoes.pessoa) AS celular
              , bas.sp_email(sel.inscricoes.pessoa)   AS email
              , (
                    SELECT token
                    FROM ava.provasonline,
                         sel.respondentesprovas,
                         sel.provas
                    WHERE ava.provasonline.valorcampo = sel.respondentesprovas.codigo
                      AND sel.respondentesprovas.inscricaofase = sel.inscricoesfases.codigo
                      AND sel.provas.codigo = sel.respondentesprovas.prova
                      AND sel.provas.objetiva = TRUE
                )                                     AS token_objetiva
              , (
                    SELECT token
                    FROM ava.provasonline,
                         sel.respondentesprovas,
                         sel.provas
                    WHERE ava.provasonline.valorcampo = sel.respondentesprovas.codigo
                      AND sel.respondentesprovas.inscricaofase = sel.inscricoesfases.codigo
                      AND sel.provas.codigo = sel.respondentesprovas.prova
                      AND sel.provas.objetiva = FALSE
                )                                     AS token_redacao
         FROM sel.provas
         JOIN sel.vw_fasesprovas ON sel.vw_fasesprovas.prova = sel.provas.codigo
         JOIN sel.fases ON sel.fases.codigo = sel.vw_fasesprovas.fase
         JOIN sel.ocorrencias ON sel.ocorrencias.codigo = sel.fases.ocorrencia
         JOIN sel.processosseletivos ON sel.processosseletivos.codigo = sel.ocorrencias.processoseletivo
         JOIN sel.inscricoesfases ON sel.inscricoesfases.fase = sel.fases.codigo
         JOIN sel.statusinscricoesfases ON sel.statusinscricoesfases.codigo = sel.inscricoesfases.status
         JOIN sel.inscricoes ON sel.inscricoes.codigo = sel.inscricoesfases.inscricao
         JOIN bas.pessoas ON bas.pessoas.codigo = sel.inscricoes.pessoa
         WHERE sel.fases.codigo = 33241
           AND sel.provas.objetiva = TRUE
         ORDER BY bas.pessoas.nome
     ) AS T;


SELECT DISTINCT
       sel.inscricoesfases.codigo AS inscricaofase,
       sel.provas.codigo          AS prova
FROM sel.provas,
     sel.vw_fasesprovas,
     sel.fases,
     sel.ocorrencias,
     sel.processosseletivos,
     sel.inscricoesfases,
     sel.inscricoes,
     bas.pessoas
WHERE TRUE
  --AND (sel.provas.data::VARCHAR || ' ' || sel.provas.horainicio::VARCHAR)::TIMESTAMP
  --  BETWEEN (NOW() - INTERVAL '20 minutes')::TIMESTAMP
  --  AND (NOW() + INTERVAL '1 minutes')::TIMESTAMP
  AND sel.vw_fasesprovas.prova = sel.provas.codigo
  AND sel.fases.codigo = sel.vw_fasesprovas.fase
  AND sel.ocorrencias.codigo = sel.fases.ocorrencia
  AND sel.processosseletivos.codigo = sel.ocorrencias.processoseletivo
  AND sel.inscricoesfases.fase = sel.fases.codigo
  AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
  AND bas.pessoas.codigo = sel.inscricoes.pessoa
  AND sel.inscricoesfases.status = 1
  AND sel.fases.codigo = 33241
  AND (sel.inscricoesfases.codigo, sel.provas.codigo) NOT IN (
                                                                 SELECT sel.respondentesprovas.inscricaofase,
                                                                        sel.respondentesprovas.prova
                                                                 FROM sel.respondentesprovas
                                                                 WHERE sel.respondentesprovas.dataehoraliberacao IS NOT NULL
                                                             );


SELECT *
FROM sis.emailbatch
WHERE assunto = 'SIMULADO ENEM'
AND dataregistro::DATE = CURRENT_DATE
ORDER BY 1 DESC;

SELECT DISTINCT
       sel.inscricoesfases.codigo AS inscricaofase,
       sel.provas.codigo          AS prova
FROM sel.provas,
     sel.vw_fasesprovas,
     sel.fases,
     sel.ocorrencias,
     sel.processosseletivos,
     sel.inscricoesfases,
     sel.inscricoes,
     bas.pessoas
WHERE TRUE
--  AND (sel.provas.data::VARCHAR || ' ' || sel.provas.horainicio::VARCHAR)::TIMESTAMP
--    BETWEEN (NOW() - INTERVAL '20 minutes')::TIMESTAMP
--    AND (NOW() + INTERVAL '1 minutes')::TIMESTAMP
  AND sel.vw_fasesprovas.prova = sel.provas.codigo
  AND sel.fases.codigo = sel.vw_fasesprovas.fase
  AND sel.ocorrencias.codigo = sel.fases.ocorrencia
  AND sel.processosseletivos.codigo = sel.ocorrencias.processoseletivo
--  AND sel.processosseletivos.codigo = sel.sp_processoseletivo_por_periodoletivo(gra.sp_periodoletivo_matricula())
  AND sel.inscricoesfases.fase = sel.fases.codigo
  AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
  AND bas.pessoas.codigo = sel.inscricoes.pessoa
  AND sel.inscricoesfases.status = 1
  AND sel.fases.codigo = 33241
  AND (sel.inscricoesfases.codigo, sel.provas.codigo) NOT IN (
      SELECT sel.respondentesprovas.inscricaofase,
             sel.respondentesprovas.prova
      FROM sel.respondentesprovas
      WHERE sel.respondentesprovas.dataehoraliberacao IS NOT NULL
    );



SELECT COUNT(DISTINCT pessoa) provas,
       COUNT(DISTINCT pessoa) FILTER (WHERE datainiciorealizacao is not null) provas_iniciadas,
       COUNT(DISTINCT pessoa) FILTER (WHERE provasonline.datafimrealizacao is not null) provas_finalizadas
FROM ava.provasonline,
     sel.respondentesprovas,
     sel.inscricoesfases,
     sel.provas
WHERE ava.provasonline.valorcampo = sel.respondentesprovas.codigo
  AND sel.respondentesprovas.inscricaofase = sel.inscricoesfases.codigo
  AND sel.inscricoesfases.fase = 33241
  AND sel.provas.codigo = sel.respondentesprovas.prova;





SELECT ava.provasonline.*
FROM ava.provasonline,
     sel.respondentesprovas,
     sel.inscricoesfases,
     sel.provas
WHERE ava.provasonline.valorcampo = sel.respondentesprovas.codigo
  AND sel.respondentesprovas.inscricaofase = sel.inscricoesfases.codigo
  AND sel.inscricoesfases.fase = 33237
  AND sel.provas.codigo = sel.respondentesprovas.prova
AND ava.provasonline.datafimrealizacao is not NULL;



SELECT *,
       bas.sp_cpf(bas.pessoas.codigo, FALSE) AS cpf,
       bas.sp_cpf(bas.pessoas.codigo, FALSE) != cpf
FROM tmp_inscricoes_simulado_enem,
     bas.emails,
     bas.pessoas_emails,
     bas.pessoas
WHERE TRIM(bas.emails.endereco) = tmp_inscricoes_simulado_enem.email
  AND bas.pessoas_emails.email = bas.emails.codigo
  AND bas.pessoas_emails.pessoa != tmp_inscricoes_simulado_enem.pessoa_id
  AND bas.pessoas.codigo = bas.pessoas_emails.pessoa;



SELECT *
FROM bas.pessoas_emails,
     bas.emails,
     bas.pessoas
WHERE pessoa IN (105375, 187893, 272506)
  AND bas.emails.codigo = bas.pessoas_emails.email
  AND bas.pessoas.codigo = bas.pessoas_emails.pessoa;

--COMMIT
ROLLBACK;
BEGIN;
DELETE
FROM bas.pessoas_emails
WHERE email IN (173599, 251136);
DELETE
FROM bas.emails
WHERE codigo IN (173599, 251136);



SELECT *
FROM bas.emails,
     bas.pessoas_emails,
     bas.pessoas
WHERE bas.emails.endereco = 'angelilhagov@gmail.com'
  AND bas.pessoas_emails.email = bas.emails.codigo
  AND bas.pessoas.codigo = bas.pessoas_emails.pessoa


--34948,512958

SELECT bas.sp_cpf(codigo), bas.sp_emails(codigo), *
FROM bas.pessoas
WHERE bas.pessoas.codigo IN (485214, 510536)