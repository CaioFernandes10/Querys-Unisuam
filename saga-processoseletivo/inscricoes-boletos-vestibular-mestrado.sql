--Solicito acesso a um relatório de boletos pagos dos candidatos inscritos nos processos seletivos do mestrado e doutorado.
SELECT processoseletivo,
       ocorrencia,
       inscricao,
       candidato,
       status_inscricao,
       boleto,
       TO_CHAR(vencimento, 'dd/mm/yyyy') AS vencimento,
       status_boleto
FROM (
         SELECT sel.processosseletivos.codigo                                                     AS processo_seletivo_id,
                sel.processosseletivos.descricao                                                  AS processoseletivo,
                sel.ocorrencias.descricao                                                         AS ocorrencia,
                sel.inscricoes.label                                                              AS inscricao,
                bas.pessoas.nome                                                                  AS candidato,
                sel.statusinscricoesfases.descricao                                               AS status_inscricao,
                car.boletos.nome                                                                  AS boleto,
                car.boletos.datavencto                                                            AS vencimento,
                car.statusboletos.descricao                                                       AS status_boleto,
                sel.inscricoes.codigo,
                car.boletos.codigo,
                RANK() OVER (PARTITION BY sel.inscricoes.codigo ORDER BY car.boletos.codigo DESC) AS posicao
         FROM sel.ocorrencias,
              sel.processosseletivos,
              sel.fases,
              sel.inscricoesfases,
              sel.inscricoes,
              sel.statusinscricoesfases,
              bas.pessoas,
              car.devedores,
              car.debitos,
              ven.formasrecporservico,
              ven.servicos,
              car.boletos,
              car.statusboletos
         WHERE sel.ocorrencias.tipo = 3
           AND sel.processosseletivos.codigo = sel.ocorrencias.processoseletivo
           AND sel.fases.ocorrencia = sel.ocorrencias.codigo
           AND sel.inscricoesfases.fase = sel.fases.codigo
           AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
           AND sel.statusinscricoesfases.codigo = sel.inscricoesfases.status
           AND bas.pessoas.codigo = sel.inscricoes.pessoa
           AND car.devedores.tipo = 13
           AND car.devedores.valorcampo = sel.inscricoes.codigo
           AND car.debitos.devedor = car.devedores.codigo
           AND ven.formasrecporservico.codigo = car.debitos.formarecservico
           AND ven.servicos.codigo = ven.formasrecporservico.servico
           AND car.boletos.debito = car.debitos.codigo
           AND car.statusboletos.codigo = car.boletos.status
         GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
         ORDER BY 1, 4
     ) dados
WHERE dados.posicao = 1;

