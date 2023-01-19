DROP TABLE IF EXISTS tmp_nps_resultado;
CREATE TEMPORARY TABLE tmp_nps_resultado AS
SELECT gra.periodosletivos.label       AS periodoletivo_label,
       gra.periodosletivos.datainicial AS periodoletivo_inicio,
       gra.periodosletivos.datafinal   AS periodoletivo_fim,
       gra.professores.codigo          AS professor_id,
       gra.professores.label           AS professor_matricula,
       gra.professores.nomecurto       AS professor_nome,
       gra.disciplinas.codigo          AS disciplina_id,
       gra.disciplinas.label           AS disciplina_label,
       gra.disciplinas.nome            AS disciplina_nome,
       turma_unidade.codigo            AS turma_unidade_id,
       turma_unidade.sigla             AS turma_unidade_sigla,
       turma_unidade.nomecurto         AS turma_unidade_nome,
       turma_habilitacao.codigo        AS turma_habilitacao_id,
       turma_habilitacao.mnemonico     AS turma_habilitacao_mnemonico,
       turma_habilitacao.descricao ||
       CASE
           WHEN turma_curso.modalidade != 1
               THEN ' (' || turma_modalidade.descricao || ')'
           ELSE ''
           END                         AS turma_habilitacao_descricao,
       turma_modalidade.codigo         AS turma_modalidade_id,
       turma_modalidade.label          AS turma_modalidade_label,
       turma_modalidade.descricao      AS turma_modalidade_descricao,
       turma_turno.codigo              AS turma_turno_id,
       turma_turno.label               AS turma_turno_label,
       turma_turno.descricao           AS turma_turno_descricao,
       aluno_unidade.codigo            AS aluno_unidade_id,
       aluno_unidade.sigla             AS aluno_unidade_sigla,
       aluno_unidade.nomecurto         AS aluno_unidade_nome,
       aluno_habilitacao.codigo        AS aluno_habilitacao_id,
       aluno_habilitacao.mnemonico     AS aluno_habilitacao_mnemonico,
       aluno_habilitacao.descricao ||
       CASE
           WHEN aluno_curso.modalidade != 1
               THEN ' (' || aluno_modalidade.descricao || ')'
           ELSE ''
           END                         AS aluno_habilitacao_descricao,
       aluno_modalidade.codigo         AS aluno_modalidade_id,
       aluno_modalidade.label          AS aluno_modalidade_label,
       aluno_modalidade.descricao      AS aluno_modalidade_descricao,
       aluno_turno.codigo              AS aluno_turno_id,
       aluno_turno.label               AS aluno_turno_label,
       aluno_turno.descricao           AS aluno_turno_descricao
FROM (
         SELECT DISTINCT
                distribuicao_graduacao,
                professor,
                disciplina,
                turma_unidade,
                turma_estrutura,
                turma_turno,
                aluno_unidade,
                aluno_estrutura,
                aluno_turno
         FROM nps.respondentes_alunos_graduacao
     ) respondentes
JOIN nps.distribuicoes_graduacao
     ON nps.distribuicoes_graduacao.codigo = respondentes.distribuicao_graduacao
JOIN gra.turmasdisciplinas ON gra.turmasdisciplinas.codigo = nps.distribuicoes_graduacao.turma_disciplina
JOIN gra.turmas ON gra.turmas.codigo = gra.turmasdisciplinas.turma
JOIN gra.periodosletivos ON gra.periodosletivos.codigo = gra.turmas.periodoletivo
JOIN gra.professores ON gra.professores.codigo = respondentes.professor
JOIN gra.disciplinas ON gra.disciplinas.codigo = respondentes.disciplina
JOIN bas.unidades turma_unidade ON turma_unidade.codigo = respondentes.turma_unidade
JOIN gra.estruturas turma_estrutura
     ON turma_estrutura.codigo = respondentes.turma_estrutura
JOIN gra.habilitacoes turma_habilitacao ON turma_habilitacao.codigo = turma_estrutura.habilitacao
JOIN gra.cursos turma_curso ON turma_curso.codigo = turma_habilitacao.curso
JOIN gra.modalidadescurso turma_modalidade ON turma_modalidade.codigo = turma_curso.modalidade
JOIN gra.turnos turma_turno ON turma_turno.codigo = respondentes.turma_turno
JOIN bas.unidades aluno_unidade ON aluno_unidade.codigo = respondentes.aluno_unidade
JOIN gra.estruturas aluno_estrutura
     ON aluno_estrutura.codigo = respondentes.aluno_estrutura
JOIN gra.habilitacoes aluno_habilitacao ON aluno_habilitacao.codigo = aluno_estrutura.habilitacao
JOIN gra.cursos aluno_curso ON aluno_curso.codigo = aluno_habilitacao.curso
JOIN gra.modalidadescurso aluno_modalidade ON aluno_modalidade.codigo = aluno_curso.modalidade
JOIN gra.turnos aluno_turno ON aluno_turno.codigo = respondentes.aluno_turno
WHERE TRUE
  AND gra.periodosletivos.label = '2021-2';


SELECT *
FROM tmp_nps_resultado;