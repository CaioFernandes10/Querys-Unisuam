

SELECT matricula, nome, status
FROM (
     SELECT bas.pessoas.nome,
            mes.alunos.label                                      AS matricula,
            mes.statusmatriculas.descricao                        AS status,
            mes.matriculas.aluno                                  AS alunos_id,
            mes.matriculas.codigo                                 AS matricula_id,
            car.devedores.codigo                                  AS devedor_id,
            mes.matriculas.status                                 AS status_id,
            cnt.data IS NOT NULL                                  AS assinado,
            mes.sp_verifica_renovacao_contrato(mes.alunos.codigo) AS renovacao,
            NOT car.sp_verificainadimplenciadevedor_simples(
                    car.devedores.codigo,
                    TRUE,
                    TRUE,
                    TRUE,
                    '31/12/2021'::DATE)                                 AS adimplente
     FROM mes.alunos
     JOIN mes.matriculas ON mes.matriculas.aluno = mes.alunos.codigo
     JOIN mes.statusmatriculas ON mes.statusmatriculas.codigo = mes.matriculas.status
     JOIN bas.pessoas ON bas.pessoas.codigo = mes.alunos.pessoa
     JOIN car.devedores ON car.devedores.valorcampo = mes.alunos.codigo AND car.devedores.tipo = 6
     LEFT JOIN (
               SELECT mes.alunoscontratos.aluno,
                      mes.alunoscontratos.data
               FROM mes.alunoscontratos,
                    mes.contratos,
                    mes.periodosletivos
               WHERE mes.contratos.codigo = mes.alunoscontratos.contrato
                 AND mes.periodosletivos.codigo = mes.contratos.periodoletivo
                 AND mes.periodosletivos.label = mes.sp_periodoletivo_atual()
               ) cnt ON cnt.aluno = mes.alunos.codigo
     WHERE mes.matriculas.status IN (1, 2)
       AND mes.matriculas.codigo = (
                                   SELECT codigo1
                                   FROM mes.sp_matricula01(mes.alunos.codigo)
                                   )
     ) dados
WHERE dados.renovacao = TRUE
  AND dados.assinado = TRUE
  AND dados.adimplente = FALSE;