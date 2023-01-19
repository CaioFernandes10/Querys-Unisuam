DROP TABLE IF EXISTS tmp_datas_provas;
CREATE TEMPORARY TABLE tmp_datas_provas AS
SELECT DISTINCT
       bas.unidades.nomesite  AS unidade,
       sel.provas.data        AS data,
       sel.provas.horainicio  AS horario,
       sel.ocorrencias.codigo AS ocorrencia_id,
       sel.fases.codigo       AS fase_id,
       bas.unidades.codigo    AS unidade_id,
       CASE EXTRACT(DOW FROM sel.provas.data)
           WHEN 0 THEN 'Domingo'
           WHEN 1 THEN 'Segunda-feira'
           WHEN 2 THEN 'Terça-feira'
           WHEN 3 THEN 'Quarta-feira'
           WHEN 4 THEN 'Quinta-feira'
           WHEN 5 THEN 'Sexta-feira'
           WHEN 6 THEN 'Sábado'
           END                AS dia_semana
FROM sel.ocorrencias,
     sel.fases,
     sel.vw_fasesprovas,
     sel.provas,
     sel.fasessalas,
     bas.salas,
     bas.unidades
WHERE sel.ocorrencias.tipo = 4
  AND sel.ocorrencias.processoseletivo = (
                                             SELECT sel.sp_processoseletivo_por_periodoletivo(gra.sp_periodoletivo_matricula())
                                         )
  AND (CURRENT_TIMESTAMP BETWEEN sel.ocorrencias.inscricaoextini AND sel.ocorrencias.inscricaoextfim)
  AND sel.fases.ocorrencia = sel.ocorrencias.codigo
  AND sel.fases.status = 1
  AND sel.fases.status != 3
  AND sel.vw_fasesprovas.fase = sel.fases.codigo
  AND sel.provas.codigo = sel.vw_fasesprovas.prova
  AND sel.provas.data >= CURRENT_DATE
  AND sel.fasessalas.fase = sel.fases.codigo
  AND bas.salas.codigo = sel.fasessalas.sala
  AND bas.unidades.codigo = bas.salas.unidade
  AND bas.salas.capacidadeps > (
                                   SELECT COUNT(*)
                                   FROM sel.inscricoesfases
                                   WHERE status != 9
                                     AND fase = sel.fasessalas.fase
                                     AND sala = bas.salas.codigo
                               )
  AND COALESCE(sel.ocorrencias.limitedeinscricoes,
               float4 'INFINITY') > (
                                        SELECT COUNT(*)
                                        FROM sel.inscricoesfases
                                        WHERE status != 9
                                          AND fase = sel.fases.codigo
                                    )
ORDER BY 1, 2, 3;

DELETE
FROM tmp_datas_provas
WHERE fase_id = (
                    SELECT param.fase_id[2]
                    FROM (
                             SELECT STRING_TO_ARRAY(
                                            sis.sp_parametro01('sel0028',
                                                               sel.sp_processoseletivo_por_periodoletivo(gra.sp_periodoletivo_matricula())
                                                ), '|#|') AS fase_id
                         ) param
                    WHERE param.fase_id[1] != 0
                );


SELECT * FROM tmp_datas_provas




SELECT * FROM bas.unidades where codigo = 4


select * from sel.sp_retornar_inscricoes(611534, true)
