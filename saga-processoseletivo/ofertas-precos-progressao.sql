DROP TABLE IF EXISTS tmp_matricula_online_ofertas;
CREATE TEMPORARY TABLE tmp_matricula_online_ofertas AS
SELECT bas.estados.sigla                                        AS estado,
       bas.localidades.descricao                                AS cidade,
       COALESCE(gra.habilitacoes.nomesite,
                gra.habilitacoes.descricao)                     AS habilitacao,
       gra.estruturas.label                                     AS estrutura,
       gra.modalidadescurso.descricao                           AS modalidade,
       COALESCE(bas.unidades.nomesite,
                bas.unidades.nomecurto)                         AS unidade,
       gra.turnos.descricao                                     AS turno,
       CASE WHEN vagas > 0 THEN TRUE ELSE FALSE END             AS fi_vestibular,
       CASE WHEN vagas > 0 THEN TRUE ELSE FALSE END             AS fi_enem,
       CASE WHEN vagas_portador > 0 THEN TRUE ELSE FALSE END    AS fi_portador,
       CASE WHEN vagas_transferido > 0 THEN TRUE ELSE FALSE END AS fi_transferencia,
       CASE WHEN vagas_solidario > 0 THEN TRUE ELSE FALSE END   AS fi_solidario,
       COALESCE(sel.objetivos.ocultar, FALSE)                   AS ocultar,
       sel.objetivos.codigo                                     AS objetivo_id,
       bas.estados.codigo                                       AS estado_id,
       bas.localidades.codigo                                   AS cidade_id,
       bas.unidades.codigo                                      AS unidade_id,
       gra.cursos.codigo                                        AS curso_id,
       gra.habilitacoes.codigo                                  AS habilitacao_id,
       sel.objetivos.valorparametro3                            AS estrutura_id,
       gra.modalidadescurso.codigo                              AS modalidade_id,
       gra.turnos.codigo                                        AS turno_id,
       sel.objetivos.valorparametro2                            AS periodoletivo_id,
       0                                                        AS vagas_disponiveis,
       sel.objetivos.vagas,
       sel.objetivos.vagas_solidario
FROM sel.objetivos,
     gra.estruturas,
     gra.habilitacoes,
     gra.cursos,
     gra.modalidadescurso,
     gra.turnos,
     bas.unidades,
     bas.empresas,
     bas.empresas_enderecos,
     bas.enderecos,
     bas.estados,
     bas.localidades
WHERE sel.objetivos.processoseletivo = (
                                           SELECT sel.sp_processoseletivo_por_periodoletivo((
                                                                                                SELECT gra.sp_periodoletivo_matricula()
                                                                                            ))
                                       )
  AND gra.estruturas.codigo = sel.objetivos.valorparametro3
  AND gra.habilitacoes.codigo = gra.estruturas.habilitacao
  AND gra.cursos.codigo = gra.habilitacoes.curso
  AND gra.modalidadescurso.codigo = gra.cursos.modalidade
  AND gra.turnos.codigo = sel.objetivos.valorparametro4
  AND bas.unidades.codigo = sel.objetivos.valorparametro1
  AND bas.empresas.codigo = bas.unidades.empresa
  AND bas.empresas_enderecos.empresa = bas.empresas.codigo
  AND bas.enderecos.codigo = bas.empresas_enderecos.endereco
  AND bas.estados.codigo = bas.enderecos.estado
  AND bas.localidades.codigo = bas.enderecos.localidade;

ALTER TABLE tmp_matricula_online_ofertas
    ADD COLUMN progressao BOOLEAN DEFAULT FALSE;

UPDATE tmp_matricula_online_ofertas
SET progressao = TRUE
WHERE (periodoletivo_id, estrutura_id, turno_id)
          IN (
                 SELECT DISTINCT
                        periodoletivo,
                        estrutura,
                        turno
                 FROM gra.estruturasoferecidas
             );

ALTER TABLE tmp_matricula_online_ofertas
    ADD COLUMN preco BOOLEAN DEFAULT FALSE;

UPDATE tmp_matricula_online_ofertas
SET preco = TRUE
WHERE (unidade_id, periodoletivo_id, curso_id, turno_id)
          IN (
                 SELECT DISTINCT
                        valorcampo1,
                        valorcampo2,
                        valorcampo3,
                        valorcampo4
                 FROM ven.servicos,
                      gra.periodosletivos,
                      ven.formasrecporservico,
                      ven.formasrecebimento
                 WHERE ven.servicos.tipo = 2
                   AND gra.periodosletivos.codigo = ven.servicos.valorcampo2
                   AND gra.periodosletivos.label = gra.sp_periodoletivo_matricula()
                   AND ven.formasrecporservico.servico = ven.servicos.codigo
                   AND ven.formasrecebimento.codigo = ven.formasrecporservico.formarecebimento
                   AND ven.formasrecebimento.tabela = ven.sp_tabeladecalouro(ven.servicos.valorcampo1,
                                                                             ven.servicos.valorcampo2,
                                                                             ven.servicos.valorcampo3,
                                                                             ven.servicos.valorcampo4,
                                                                             1)
             );


--DELETE
--FROM tmp_matricula_online_ofertas
--WHERE (preco = FALSE OR progressao = FALSE OR ocultar = TRUE);

UPDATE tmp_matricula_online_ofertas
SET vagas_disponiveis = sel.sp_retornavagasgraduacao((
                                                         SELECT label
                                                         FROM gra.periodosletivos
                                                         WHERE codigo = periodoletivo_id
                                                     ), unidade_id, estrutura_id, turno_id);


UPDATE tmp_matricula_online_ofertas
SET fi_vestibular = FALSE,
    fi_enem       = FALSE
WHERE vagas_disponiveis = 0;

--relatorio-dos-sonhos-da-barbara
SELECT estado,
       cidade,
       habilitacao,
       estrutura,
       modalidade,
       unidade,
       turno,
       vagas,
       vagas_disponiveis,
       vagas_solidario                                           AS vagas_solidario,
       CASE ocultar WHEN TRUE THEN 'SIM' ELSE 'NAO' END          AS ocultar,
       CASE fi_vestibular WHEN TRUE THEN 'SIM' ELSE 'NAO' END    AS vestibular,
       CASE fi_enem WHEN TRUE THEN 'SIM' ELSE 'NAO' END          AS enem,
       CASE fi_portador WHEN TRUE THEN 'SIM' ELSE 'NAO' END      AS portador,
       CASE fi_transferencia WHEN TRUE THEN 'SIM' ELSE 'NAO' END AS trasferencia,
       CASE progressao WHEN TRUE THEN 'SIM' ELSE 'NAO' END       AS progressao,
       CASE preco WHEN TRUE THEN 'SIM' ELSE 'NAO' END            AS preco
FROM tmp_matricula_online_ofertas
--WHERE not (preco = FALSE OR progressao = FALSE OR ocultar = TRUE)
ORDER BY 1, 2, 3, 4, 5, 6;


