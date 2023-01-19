DROP TABLE IF EXISTS tmp_pendencias_documentos;
CREATE TEMPORARY TABLE tmp_pendencias_documentos AS
SELECT pro.encaminhamentos.requerimento AS requerimento_id,
       pro.protocolos.pessoa            AS pessoa_id
FROM pro.requerimentos,
     pro.encaminhamentos,
     pro.vw_ultimo_encaminhamento,
     pro.protocolos
WHERE pro.requerimentos.tiporequerimento = 40354
  AND pro.encaminhamentos.requerimento = pro.requerimentos.codigo
  AND pro.encaminhamentos.status IN (1, 6)
  AND pro.vw_ultimo_encaminhamento.requerimento = pro.requerimentos.codigo
  AND pro.vw_ultimo_encaminhamento.codigo = pro.encaminhamentos.codigo
  AND pro.protocolos.codigo = pro.requerimentos.protocolo;


DROP TABLE IF EXISTS tmp_pendencias_documentos_detalhes;
CREATE TEMPORARY TABLE tmp_pendencias_documentos_detalhes AS
SELECT tmp_pendencias_documentos.pessoa_id,
       bas.tiposdocumento.descricaosimples AS documento
FROM tmp_pendencias_documentos,
     liv.ocorrencias,
     liv.tiposocorrencias,
     bas.tiposdocumento
WHERE liv.ocorrencias.valorcampo = tmp_pendencias_documentos.pessoa_id
  AND liv.ocorrencias.ativa = TRUE
  AND liv.tiposocorrencias.codigo = liv.ocorrencias.tipoocorrencia
  AND liv.tiposocorrencias.area = 1
  AND bas.tiposdocumento.codigo = liv.tiposocorrencias.tipodocumento;


--106
-- FINALIZAR O PROTOCOLO
SELECT *
FROM tmp_pendencias_documentos doc
LEFT JOIN tmp_pendencias_documentos_detalhes det ON det.pessoa_id = doc.pessoa_id
WHERE det.pessoa_id IS NULL;

--542
-- COLOCAR EM EXIGENCIA NOVAMENTE
-- ENVIAR EMAIL COM OS DOCUMENTOS PENDENTES
SELECT doc.pessoa_id,
       STRING_AGG(DISTINCT det.documento, '|@|' ORDER BY det.documento) AS documentos
FROM tmp_pendencias_documentos doc
LEFT JOIN tmp_pendencias_documentos_detalhes det ON det.pessoa_id = doc.pessoa_id
WHERE det.pessoa_id IS NOT NULL
GROUP BY 1;





