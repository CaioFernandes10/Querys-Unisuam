SELECT bas.unidades.nomesite AS unidade,
       bas.blocos.label      AS bloco,
       bas.salas.label       AS sala,
       bas.salas.capacidadeps
FROM sel.processosseletivos,
     sel.ocorrencias,
     sel.fases,
     sel.fasessalas,
     bas.salas,
     bas.blocos,
     bas.unidades
WHERE sel.ocorrencias.processoseletivo = sel.processosseletivos.codigo
  AND sel.ocorrencias.tipo = 4
  AND sel.fases.ocorrencia = sel.ocorrencias.codigo
  AND sel.fasessalas.fase = sel.fases.codigo
  AND bas.salas.codigo = sel.fasessalas.sala
  AND bas.blocos.codigo = bas.salas.bloco
  AND bas.unidades.codigo = bas.blocos.unidade
  AND sel.processosseletivos.codigo = (
                                          SELECT sel.sp_processoseletivo_por_periodoletivo((
                                                                                               SELECT gra.sp_periodoletivo_matricula()
                                                                                           ))
                                      )
ORDER BY 1, 2, 3;