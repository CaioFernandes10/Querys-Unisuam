DROP TABLE IF EXISTS tmp_pendencias_documentos;
CREATE TEMPORARY TABLE tmp_pendencias_documentos AS
SELECT pro.encaminhamentos.requerimento AS requerimento_id,
       pro.protocolos.pessoa            AS pessoa_id,
       pro.protocolos.matricula
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
       tmp_pendencias_documentos.matricula,
       bas.tiposdocumento.descricaosimples AS documento,
       bas.tiposdocumento.codigo           AS tipodocumento
FROM tmp_pendencias_documentos,
     liv.ocorrencias,
     liv.tiposocorrencias,
     bas.tiposdocumento
WHERE liv.ocorrencias.valorcampo = tmp_pendencias_documentos.pessoa_id
  AND liv.ocorrencias.ativa = TRUE
  AND liv.tiposocorrencias.codigo = liv.ocorrencias.tipoocorrencia
  AND liv.tiposocorrencias.area = 1
  AND bas.tiposdocumento.codigo = liv.tiposocorrencias.tipodocumento[1];

DROP TABLE IF EXISTS tmp_protocolos_exigencia;
CREATE TEMPORARY TABLE tmp_protocolos_exigencia AS
SELECT doc.pessoa_id,
       doc.matricula,
       doc.requerimento_id,
       STRING_AGG(DISTINCT det.documento, ' , ' ORDER BY det.documento) AS documentos,
       ARRAY_AGG(det.tipodocumento)                                     AS tipodocumento
FROM tmp_pendencias_documentos doc
LEFT JOIN tmp_pendencias_documentos_detalhes det ON det.pessoa_id = doc.pessoa_id
WHERE det.pessoa_id IS NOT NULL
GROUP BY 1, 2, 3;

ALTER TABLE tmp_protocolos_exigencia
    ADD COLUMN unidade INTEGER;

UPDATE tmp_protocolos_exigencia
SET unidade = gra.inscricoes.unidade_unid
FROM gra.alunos,
     gra.inscricoes
WHERE gra.alunos.label = tmp_protocolos_exigencia.matricula
  AND gra.inscricoes.aluno = gra.alunos.codigo
  AND gra.inscricoes.codigo = gra.sp_inscricao_atual(gra.alunos.codigo);

ALTER TABLE tmp_protocolos_exigencia
    ADD COLUMN departamento INTEGER;

UPDATE tmp_protocolos_exigencia
SET departamento = 1278
WHERE tmp_protocolos_exigencia.unidade = 4;

UPDATE tmp_protocolos_exigencia
SET departamento = 1195
WHERE tmp_protocolos_exigencia.unidade = 5;

UPDATE tmp_protocolos_exigencia
SET departamento = 1199
WHERE tmp_protocolos_exigencia.unidade = 8;

UPDATE tmp_protocolos_exigencia
SET departamento = 1197
WHERE tmp_protocolos_exigencia.unidade = 9;

UPDATE tmp_protocolos_exigencia
SET departamento = 1278
WHERE tmp_protocolos_exigencia.departamento IS NULL;


--COMMIT;
ROLLBACK;
BEGIN;

INSERT INTO pro.encaminhamentos(status, requerimento, usuario,
                                parecerinterno, parecerexterno,
                                departamento, deferido, documentos)
SELECT 6::INTEGER,
       requerimento_id,
       5::INTEGER,
       'Documentos pendentes: ' || ' ' || tmp_protocolos_exigencia.documentos ::VARCHAR,
       'Documentos pendentes: ' || ' ' || tmp_protocolos_exigencia.documentos::VARCHAR,
       tmp_protocolos_exigencia.departamento,
       FALSE,
       tipodocumento
FROM tmp_protocolos_exigencia,
     pro.vw_ultimo_encaminhamento,
     pro.encaminhamentos
WHERE pro.vw_ultimo_encaminhamento.requerimento = tmp_protocolos_exigencia.requerimento_id
  AND pro.encaminhamentos.codigo = pro.vw_ultimo_encaminhamento.codigo;

SELECT pro.requerimentos.codigo AS requerimento_id,
       pro.protocolos.codigo    AS protocolo_id,
       pro.protocolos.label,
       pro.protocolos.matricula,
       tmp_protocolos_exigencia.departamento,
       pro.encaminhamentos.documentos,
       pro.encaminhamentos.parecerinterno
FROM tmp_protocolos_exigencia,
     pro.vw_ultimo_encaminhamento,
     pro.encaminhamentos,
     pro.requerimentos,
     pro.protocolos
WHERE pro.vw_ultimo_encaminhamento.requerimento = tmp_protocolos_exigencia.requerimento_id
  AND pro.encaminhamentos.codigo = pro.vw_ultimo_encaminhamento.codigo
  AND pro.requerimentos.codigo = pro.encaminhamentos.requerimento
  AND pro.protocolos.codigo = pro.requerimentos.protocolo;
