-- OS ALUNOS MODULARES
DROP TABLE IF EXISTS tmp_inconsistencias_modulares_alunos;
CREATE TEMPORARY TABLE tmp_inconsistencias_modulares_alunos AS
SELECT gra.periodosletivos.label::VARCHAR    AS periodoletivo,
       gra.alunos.label::VARCHAR             AS matricula,
       bas.pessoas.nome                      AS nome,
       gra.habilitacoes.mnemonico::VARCHAR   AS habilitacao,
       gra.estruturas.label::VARCHAR         AS estrutura,
       bas.unidades.sigla::VARCHAR           AS unidade,
       gra.turnos.label::VARCHAR             AS turno,
       gra.statusmatriculas.descricaosimples AS status,
       gra.historicos.codigo                 AS historico_id,
       gra.matriculas.codigo                 AS matricula_id,
       gra.estruturas.codigo                 AS estrutura_id,
       gra.turnos.codigo                     AS turno_id
FROM gra.matriculas,
     gra.periodosletivos,
     gra.historicos,
     gra.inscricoes,
     gra.alunos,
     bas.pessoas,
     gra.estruturas,
     gra.habilitacoes,
     gra.turnos,
     bas.unidades,
     gra.statusmatriculas
WHERE gra.matriculas.status IN (1, 5)
  AND gra.periodosletivos.codigo = gra.matriculas.periodoletivo
  AND gra.periodosletivos.label = gra.sp_periodoletivo_matricula()
  AND gra.historicos.codigo = gra.matriculas.historico
  AND gra.inscricoes.codigo = gra.historicos.inscricao
  AND gra.alunos.codigo = gra.inscricoes.aluno
  AND bas.pessoas.codigo = gra.alunos.pessoa
  AND gra.estruturas.codigo = gra.historicos.estrutura
  AND gra.turnos.codigo = gra.matriculas.turno
  AND gra.habilitacoes.codigo = gra.estruturas.habilitacao
  AND bas.unidades.codigo = gra.matriculas.unidade_unid
  AND gra.statusmatriculas.codigo = gra.matriculas.status
  AND gra.estruturas.formato = 2;

DELETE
FROM tmp_inconsistencias_modulares_alunos
WHERE estrutura_id = 1693;

-- AS DISCIPLINAS EM QUE OS ALUNOS ESTAO INSCRITOS
DROP TABLE IF EXISTS tmp_inconsistencias_modulares_alunos_disciplinas;
CREATE TEMPORARY TABLE tmp_inconsistencias_modulares_alunos_disciplinas AS
SELECT tmp_inconsistencias_modulares_alunos.matricula_id,
       tmp_inconsistencias_modulares_alunos.matricula,
       gra.turmas.label::VARCHAR      AS turma,
       gra.habilitacoes.mnemonico     AS habilitacao,
       gra.estruturas.label::VARCHAR  AS estrutura,
       gra.periodos.label::INTEGER    AS periodo,
       bas.unidades.sigla::VARCHAR    AS unidade,
       gra.turnos.label::VARCHAR      AS turno,
       gra.disciplinas.codigo         AS disciplina_id,
       gra.disciplinas.label::VARCHAR AS disciplina_label,
       gra.disciplinas.nome::VARCHAR  AS disciplina,
       gra.estruturas.codigo          AS estrutura_id,
       gra.turnos.codigo              AS turno_id,
       gra.turmas.periodo             AS periodo_id,
       gra.disciplinas.modular,
       gra.periodos.estagio
FROM tmp_inconsistencias_modulares_alunos,
     gra.matriculas,
     gra.matriculasdetalhes,
     gra.turmasdisciplinas,
     gra.disciplinas,
     gra.turmas,
     gra.periodos,
     bas.unidades,
     gra.turnos,
     gra.estruturas,
     gra.habilitacoes
WHERE gra.matriculas.codigo = tmp_inconsistencias_modulares_alunos.matricula_id
  AND gra.matriculasdetalhes.matricula = gra.matriculas.codigo
  AND gra.matriculasdetalhes.status IN (1, 5)
  AND gra.turmasdisciplinas.codigo = gra.matriculasdetalhes.turmadisciplina
  AND gra.disciplinas.codigo = gra.turmasdisciplinas.disciplina
  AND gra.turmas.codigo = gra.turmasdisciplinas.turma
  AND gra.periodos.codigo = gra.turmas.periodo
  AND bas.unidades.codigo = gra.turmas.unidade_unid
  AND gra.turnos.codigo = gra.turmas.turno
  AND gra.estruturas.codigo = gra.turmas.estrutura
  AND gra.habilitacoes.codigo = gra.estruturas.habilitacao;

-- AS TURMAS MODULARES EM QUE OS ALUNOS ESTAO INSCRITOS E SUAS RESPETIVAS DISCIPLINAS (AGRUPADAS)
DROP TABLE IF EXISTS tmp_inconsistencias_modulares_alunos_disciplinas_t1;
CREATE TEMPORARY TABLE tmp_inconsistencias_modulares_alunos_disciplinas_t1 AS
SELECT tmp_inconsistencias_modulares_alunos_disciplinas.matricula_id,
       tmp_inconsistencias_modulares_alunos_disciplinas.estrutura_id,
       tmp_inconsistencias_modulares_alunos_disciplinas.periodo_id,
       ARRAY_AGG(gra.estruturasdetalhes.disciplina) AS disciplinas
FROM tmp_inconsistencias_modulares_alunos_disciplinas,
     gra.estruturasdetalhes
WHERE tmp_inconsistencias_modulares_alunos_disciplinas.modular = TRUE
  AND gra.estruturasdetalhes.estrutura = tmp_inconsistencias_modulares_alunos_disciplinas.estrutura_id
  AND gra.estruturasdetalhes.periodo = tmp_inconsistencias_modulares_alunos_disciplinas.periodo_id
  AND gra.estruturasdetalhes.tipo IN (1, 4)
GROUP BY 1, 2, 3;

-- AS DISCIPLINAS EM QUE OS ALUNOS ESTÃO INSCITAS  (AGRUPADAS)
DROP TABLE IF EXISTS tmp_inconsistencias_modulares_alunos_disciplinas_t2;
CREATE TEMPORARY TABLE tmp_inconsistencias_modulares_alunos_disciplinas_t2 AS
SELECT tmp_inconsistencias_modulares_alunos_disciplinas.matricula_id,
       tmp_inconsistencias_modulares_alunos_disciplinas.estrutura_id,
       tmp_inconsistencias_modulares_alunos_disciplinas.periodo_id,
       ARRAY_AGG(tmp_inconsistencias_modulares_alunos_disciplinas.disciplina_id) AS disciplinas
FROM tmp_inconsistencias_modulares_alunos_disciplinas
GROUP BY 1, 2, 3;

-- VERIFICACAO DE INCONSISTENCIAS DE DISCIPLINAS INSCRITAS CONTRA DISCIPLINAS DO PERIODO NA ESTRUTURA
DROP TABLE IF EXISTS tmp_inconsistencias_modulares_alunos_disciplinas_t3;
CREATE TEMPORARY TABLE tmp_inconsistencias_modulares_alunos_disciplinas_t3 AS
SELECT t1.matricula_id,
       t1.estrutura_id,
       t1.periodo_id,
       array_remove_plpgsql(t1.disciplinas, t2.disciplinas) AS inconsistente_amenos,
       array_remove_plpgsql(t2.disciplinas, t1.disciplinas) AS inconsistente_amais
FROM tmp_inconsistencias_modulares_alunos_disciplinas_t1 t1,
     tmp_inconsistencias_modulares_alunos_disciplinas_t2 t2
WHERE t1.matricula_id = t2.matricula_id
  AND t1.estrutura_id = t2.estrutura_id
  AND t1.periodo_id = t2.periodo_id;

ALTER TABLE tmp_inconsistencias_modulares_alunos
    ADD COLUMN inconsistente BOOLEAN DEFAULT FALSE;

ALTER TABLE tmp_inconsistencias_modulares_alunos
    ADD COLUMN disciplinas_amenos BOOLEAN DEFAULT FALSE;

ALTER TABLE tmp_inconsistencias_modulares_alunos
    ADD COLUMN disciplinas_amais BOOLEAN DEFAULT FALSE;

ALTER TABLE tmp_inconsistencias_modulares_alunos
    ADD COLUMN multiplos_modulos BOOLEAN DEFAULT FALSE;

ALTER TABLE tmp_inconsistencias_modulares_alunos
    ADD COLUMN estruturas_diferentes BOOLEAN DEFAULT FALSE;

UPDATE tmp_inconsistencias_modulares_alunos
SET inconsistente      = TRUE,
    disciplinas_amenos = TRUE
FROM tmp_inconsistencias_modulares_alunos_disciplinas_t3 t3
WHERE t3.matricula_id = tmp_inconsistencias_modulares_alunos.matricula_id
  AND t3.inconsistente_amenos IS NOT NULL;

UPDATE tmp_inconsistencias_modulares_alunos
SET inconsistente     = TRUE,
    disciplinas_amais = TRUE
FROM tmp_inconsistencias_modulares_alunos_disciplinas_t3 t3
WHERE t3.matricula_id = tmp_inconsistencias_modulares_alunos.matricula_id
  AND t3.inconsistente_amais IS NOT NULL;

UPDATE tmp_inconsistencias_modulares_alunos
SET inconsistente     = TRUE,
    multiplos_modulos = TRUE
WHERE matricula_id IN (
                          SELECT matricula_id
                          FROM tmp_inconsistencias_modulares_alunos_disciplinas
                          WHERE modular = TRUE
                            AND estagio = FALSE
                          GROUP BY 1
                          HAVING COUNT(*) > 1
                      );

UPDATE tmp_inconsistencias_modulares_alunos
SET inconsistente         = TRUE,
    estruturas_diferentes = TRUE
WHERE matricula_id IN (
                          SELECT alunos.matricula_id
                          FROM tmp_inconsistencias_modulares_alunos alunos,
                               tmp_inconsistencias_modulares_alunos_disciplinas disciplinas
                          WHERE disciplinas.matricula_id = alunos.matricula_id
                            AND disciplinas.modular = TRUE
                            AND disciplinas.estagio = FALSE
                            AND disciplinas.habilitacao != 'ENG'
                            AND disciplinas.estrutura_id != alunos.estrutura_id
                      );

UPDATE tmp_inconsistencias_modulares_alunos
SET inconsistente         = TRUE,
    estruturas_diferentes = TRUE
WHERE matricula_id IN (
                          SELECT alunos.matricula_id
                          FROM tmp_inconsistencias_modulares_alunos alunos,
                               tmp_inconsistencias_modulares_alunos_disciplinas disciplinas
                          WHERE disciplinas.matricula_id = alunos.matricula_id
                            AND disciplinas.modular = TRUE
                            AND disciplinas.estagio = FALSE
                            AND disciplinas.turno_id != alunos.turno_id
                      );

SELECT RANK() OVER (ORDER BY habilitacao, estrutura, turno, unidade, matricula) AS posicao,
       periodoletivo,
       matricula,
       habilitacao,
       estrutura,
       unidade,
       turno,
       status,
       CASE WHEN disciplinas_amenos THEN 'SIM' ELSE 'NAO' END                   AS disciplinas_amenos,
       CASE WHEN disciplinas_amais THEN 'SIM' ELSE 'NAO' END                    AS disciplinas_amais,
       CASE WHEN multiplos_modulos THEN 'SIM' ELSE 'NAO' END                    AS multiplos_modulos,
       CASE WHEN estruturas_diferentes THEN 'SIM' ELSE 'NAO' END                AS estruturas_diferentes
FROM tmp_inconsistencias_modulares_alunos
WHERE inconsistente = TRUE
ORDER BY 1;