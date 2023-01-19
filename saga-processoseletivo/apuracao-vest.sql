DROP TABLE IF EXISTS tmp_apuracao_vestibular;
CREATE TEMPORARY TABLE tmp_apuracao_vestibular
(
    processoseletivo      VARCHAR,
    ocorrencia            VARCHAR,
    nome                  VARCHAR,
    cpf                   VARCHAR,
    inscricao             VARCHAR,
    status_inscricao      VARCHAR,
    fase_id               INTEGER,
    inscricaofase_id      INTEGER,
    possui_prova_redacao  BOOLEAN DEFAULT FALSE,
    possui_prova_objetiva BOOLEAN DEFAULT FALSE,
    iniciou_prova         BOOLEAN DEFAULT FALSE,
    finalizou_prova       BOOLEAN DEFAULT FALSE,
    prova_expirada        BOOLEAN DEFAULT FALSE,
    correcao_expirada     BOOLEAN DEFAULT FALSE,
    possui_nota_redacao   BOOLEAN DEFAULT FALSE,
    possui_nota_objetiva  BOOLEAN DEFAULT FALSE
);

INSERT INTO tmp_apuracao_vestibular (processoseletivo, ocorrencia, nome, cpf, inscricao, status_inscricao, fase_id,
                                     inscricaofase_id)
SELECT TRIM(sel.processosseletivos.descricao),
       TRIM(sel.ocorrencias.descricao),
       bas.pessoas.nome,
       bas.sp_cpf(bas.pessoas.codigo, FALSE),
       sel.inscricoes.label,
       sel.statusinscricoesfases.descricao,
       sel.fases.codigo,
       sel.inscricoesfases.codigo
FROM sel.inscricoes,
     sel.inscricoesfases,
     sel.fases,
     sel.ocorrencias,
     sel.processosseletivos,
     bas.pessoas,
     sel.statusinscricoesfases
WHERE sel.inscricoesfases.inscricao = sel.inscricoes.codigo
  --AND sel.inscricoesfases.status = 1
  AND sel.fases.codigo = sel.inscricoesfases.fase
  AND sel.ocorrencias.codigo = sel.fases.ocorrencia
  AND sel.ocorrencias.tipo IN (1, 2, 4)
  AND sel.processosseletivos.codigo = sel.ocorrencias.processoseletivo
  AND bas.pessoas.codigo = sel.inscricoes.pessoa
  AND sel.processosseletivos.codigo = sel.sp_processoseletivo_por_periodoletivo(gra.sp_periodoletivo_matricula())
  AND sel.statusinscricoesfases.codigo = sel.inscricoesfases.status;

UPDATE tmp_apuracao_vestibular
SET prova_expirada = TRUE
FROM sel.respondentesprovas,
     ava.provasonline
WHERE sel.respondentesprovas.inscricaofase = tmp_apuracao_vestibular.inscricaofase_id
  AND ava.provasonline.valorcampo = sel.respondentesprovas.codigo
  AND ava.provasonline.tipo IN (1, 2)
  AND ava.provasonline.datafimmax < CURRENT_TIMESTAMP;

UPDATE tmp_apuracao_vestibular
SET possui_prova_objetiva = TRUE
FROM sel.vw_fasesprovas,
     sel.provas
WHERE sel.vw_fasesprovas.fase = tmp_apuracao_vestibular.fase_id
  AND sel.provas.codigo = sel.vw_fasesprovas.prova
  AND sel.provas.objetiva = TRUE;

UPDATE tmp_apuracao_vestibular
SET possui_prova_redacao = TRUE
FROM sel.vw_fasesprovas,
     sel.provas
WHERE sel.vw_fasesprovas.fase = tmp_apuracao_vestibular.fase_id
  AND sel.provas.codigo = sel.vw_fasesprovas.prova
  AND sel.provas.objetiva = FALSE;

UPDATE tmp_apuracao_vestibular
SET iniciou_prova = TRUE
FROM sel.respondentesprovas,
     ava.provasonline
WHERE sel.respondentesprovas.inscricaofase = tmp_apuracao_vestibular.inscricaofase_id
  AND ava.provasonline.valorcampo = sel.respondentesprovas.codigo
  AND ava.provasonline.tipo IN (1, 2)
  AND ava.provasonline.datainiciorealizacao IS NOT NULL;

UPDATE tmp_apuracao_vestibular
SET finalizou_prova = TRUE
FROM sel.respondentesprovas,
     ava.provasonline
WHERE sel.respondentesprovas.inscricaofase = tmp_apuracao_vestibular.inscricaofase_id
  AND ava.provasonline.valorcampo = sel.respondentesprovas.codigo
  AND ava.provasonline.tipo IN (1, 2)
  AND ava.provasonline.datafimrealizacao IS NOT NULL;

UPDATE tmp_apuracao_vestibular
SET possui_nota_redacao = TRUE
FROM sel.resultadosdisciplinas,
     sel.configuracoesdisciplinas,
     sel.disciplinas
WHERE sel.resultadosdisciplinas.inscricaofase = tmp_apuracao_vestibular.inscricaofase_id
  AND sel.configuracoesdisciplinas.codigo = sel.resultadosdisciplinas.configuracaodisciplina
  AND sel.disciplinas.codigo = sel.configuracoesdisciplinas.disciplina
  AND sel.disciplinas.tipo = 2
  AND sel.resultadosdisciplinas.pontuacao IS NOT NULL;

UPDATE tmp_apuracao_vestibular
SET possui_nota_objetiva = TRUE
FROM sel.resultadosdisciplinas,
     sel.configuracoesdisciplinas,
     sel.disciplinas
WHERE sel.resultadosdisciplinas.inscricaofase = tmp_apuracao_vestibular.inscricaofase_id
  AND sel.configuracoesdisciplinas.codigo = sel.resultadosdisciplinas.configuracaodisciplina
  AND sel.disciplinas.codigo = sel.configuracoesdisciplinas.disciplina
  AND sel.disciplinas.tipo IN (1, 3)
  AND sel.resultadosdisciplinas.pontuacao IS NOT NULL;

UPDATE tmp_apuracao_vestibular
SET correcao_expirada = TRUE
FROM sel.respondentesprovas,
     ava.provasonline
WHERE sel.respondentesprovas.inscricaofase = tmp_apuracao_vestibular.inscricaofase_id
  AND ava.provasonline.valorcampo = sel.respondentesprovas.codigo
  AND ava.provasonline.tipo IN (1, 2)
  AND ava.provasonline.datafimmax + INTERVAL '72 HOURS' < CURRENT_TIMESTAMP;

SELECT *
FROM tmp_apuracao_vestibular
WHERE (prova_expirada
    AND (
               (correcao_expirada)
               OR (NOT iniciou_prova)
               OR (NOT finalizou_prova)
               OR (possui_nota_objetiva AND possui_nota_redacao)
               OR (possui_nota_redacao AND NOT possui_prova_objetiva)
               OR (possui_nota_objetiva AND NOT possui_prova_redacao))
          );


SELECT *
FROM tmp_apuracao_vestibular
WHERE cpf = '16173906740'
ORDER BY inscricaofase_id;




