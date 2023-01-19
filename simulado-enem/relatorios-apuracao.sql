--simulado-enem-janeiro
SELECT bas.pessoas.nome                      AS candidato,
       bas.sp_cpf(sel.inscricoes.pessoa)     AS cpf,
       bas.sp_celular(sel.inscricoes.pessoa) AS celular,
       bas.sp_email(sel.inscricoes.pessoa)   AS email,
       resultado_redacao.pontuacao           AS redacao,
       resultado_objetivo.cht,
       resultado_objetivo.CNT,
       resultado_objetivo.LCT,
       resultado_objetivo.MT,
       resultado_objetivo.cht +
       resultado_objetivo.CNT +
       resultado_objetivo.LCT +
       resultado_objetivo.MT AS total
FROM sel.provas
JOIN sel.vw_fasesprovas ON sel.vw_fasesprovas.prova = sel.provas.codigo
JOIN sel.fases ON sel.fases.codigo = sel.vw_fasesprovas.fase
JOIN sel.ocorrencias ON sel.ocorrencias.codigo = sel.fases.ocorrencia
JOIN sel.processosseletivos ON sel.processosseletivos.codigo = sel.ocorrencias.processoseletivo
JOIN sel.inscricoesfases ON sel.inscricoesfases.fase = sel.fases.codigo
JOIN sel.statusinscricoesfases ON sel.statusinscricoesfases.codigo = sel.inscricoesfases.status
JOIN sel.inscricoes ON sel.inscricoes.codigo = sel.inscricoesfases.inscricao
JOIN bas.pessoas ON bas.pessoas.codigo = sel.inscricoes.pessoa
LEFT JOIN (
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
              WHERE sel.inscricoesfases.fase = 33241
                AND ava.alternativas.gabarito IS NOT NULL
                AND sel.questoesprovas.anulada = FALSE
              GROUP BY 1
          ) resultado_objetivo ON resultado_objetivo.inscricao = sel.inscricoes.codigo
LEFT JOIN (
              SELECT sel.inscricoesfases.inscricao,
                     sel.resultadosdisciplinas.pontuacao
              FROM sel.resultadosdisciplinas,
                   sel.inscricoesfases,
                   sel.configuracoesdisciplinas,
                   sel.disciplinas
              WHERE sel.inscricoesfases.codigo = sel.resultadosdisciplinas.inscricaofase
                AND sel.inscricoesfases.fase = 33241
                AND sel.configuracoesdisciplinas.codigo = sel.resultadosdisciplinas.configuracaodisciplina
                AND sel.disciplinas.codigo = sel.configuracoesdisciplinas.disciplina
                AND sel.disciplinas.tipo = 2
          ) resultado_redacao ON resultado_redacao.inscricao = sel.inscricoes.codigo
WHERE sel.fases.codigo = 33241
  AND sel.provas.objetiva = TRUE
ORDER BY bas.pessoas.nome;
