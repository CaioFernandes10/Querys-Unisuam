DROP TABLE IF EXISTS tmp_nps_resultado;
CREATE TEMPORARY TABLE tmp_nps_resultado AS
SELECT gra.professores.codigo     AS professor_id,
       gra.professores.label      AS professor_matricula,
       gra.professores.nomecurto  AS professor_nome,
       mes.disciplinas.codigo     AS disciplina_id,
       mes.disciplinas.label      AS disciplina_label,
       mes.disciplinas.nome       AS disciplina_nome,
       turma_unidade.codigo       AS turma_unidade_id,
       turma_unidade.sigla        AS turma_unidade_sigla,
       turma_unidade.nomecurto    AS turma_unidade_nome,
       turma_curso.codigo         AS turma_curso_id,
       turma_curso.mnemonico      AS turma_curso_mnemonico,
       turma_curso.nome           AS turma_curso_descricao,
       aluno_unidade.codigo       AS aluno_unidade_id,
       aluno_unidade.sigla        AS aluno_unidade_sigla,
       aluno_unidade.nomecurto    AS aluno_unidade_nome,
       aluno_curso.codigo         AS aluno_curso_id,
       aluno_curso.mnemonico      AS aluno_curso_mnemonico,
       aluno_curso.nome           AS aluno_curso_nome
FROM (
     SELECT DISTINCT
            distribuicao_mestrado,
            professor,
            disciplina,
            disciplina_oferecida,
            turma_unidade,
            aluno_unidade,
            aluno_curso
     FROM nps.respondentes_alunos_mestrado
     ) respondentes
JOIN nps.distribuicoes_mestrado distribuicao ON distribuicao.codigo = respondentes.distribuicao_mestrado
JOIN mes.disciplinas ON mes.disciplinas.codigo = respondentes.disciplina
LEFT JOIN gra.professores ON gra.professores.codigo = respondentes.professor
JOIN bas.unidades aluno_unidade ON aluno_unidade.codigo = respondentes.aluno_unidade
JOIN mes.cursos aluno_curso ON aluno_curso.codigo = respondentes.aluno_curso
JOIN bas.unidades turma_unidade ON turma_unidade.codigo = respondentes.turma_unidade
JOIN mes.cursos turma_curso ON turma_curso.codigo = respondentes.aluno_curso;


SELECT *
FROM tmp_nps_resultado;