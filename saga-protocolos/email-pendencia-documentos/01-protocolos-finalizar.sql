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
  AND bas.tiposdocumento.codigo = liv.tiposocorrencias.tipodocumento[1];

DROP TABLE IF EXISTS tmp_finalizar_protocolos;
CREATE TEMPORARY TABLE tmp_finalizar_protocolos AS
SELECT doc.*
FROM tmp_pendencias_documentos doc
LEFT JOIN tmp_pendencias_documentos_detalhes det ON det.pessoa_id = doc.pessoa_id
WHERE det.pessoa_id IS NULL;


--COMMIT;
ROLLBACK;
BEGIN;

INSERT INTO pro.encaminhamentos(status, requerimento, usuario,
                                parecerinterno, parecerexterno,
                                departamento, deferido)
SELECT 3::INTEGER,
       requerimento_id,
       5::INTEGER,
       'Prezado(a) aluno(a), os documentos solicitados foram retirados da pendência. Posteriormente solicitamos o acompanhamento do protocolo de colação de grau para eventuais exigências.'::VARCHAR,
       'Prezado(a) aluno(a), os documentos solicitados foram retirados da pendência. Posteriormente solicitamos o acompanhamento do protocolo de colação de grau para eventuais exigências.'::VARCHAR,
       543,
       FALSE
FROM tmp_finalizar_protocolos,
     pro.vw_ultimo_encaminhamento,
     pro.encaminhamentos
WHERE pro.vw_ultimo_encaminhamento.requerimento = tmp_finalizar_protocolos.requerimento_id
  AND pro.encaminhamentos.codigo = pro.vw_ultimo_encaminhamento.codigo;

SELECT pro.requerimentos.codigo AS requerimento_id,
       pro.protocolos.codigo    AS protocolo_id,
       pro.protocolos.label,
       pro.protocolos.matricula,
       pro.encaminhamentos.parecerinterno
FROM tmp_finalizar_protocolos,
     pro.vw_ultimo_encaminhamento,
     pro.encaminhamentos,
     pro.requerimentos,
     pro.protocolos
WHERE pro.vw_ultimo_encaminhamento.requerimento = tmp_finalizar_protocolos.requerimento_id
  AND pro.encaminhamentos.codigo = pro.vw_ultimo_encaminhamento.codigo
  AND pro.requerimentos.codigo = pro.encaminhamentos.requerimento
  AND pro.protocolos.codigo = pro.requerimentos.protocolo;
