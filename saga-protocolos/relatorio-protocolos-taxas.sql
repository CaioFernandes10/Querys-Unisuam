DROP TABLE IF EXISTS tmp_protocolos_taxas;
CREATE TEMPORARY TABLE tmp_protocolos_taxas AS
SELECT pro.tiposrequerimento.label     AS codigo,
       pro.tiposrequerimento.descricao AS requerimento,
       txprecos.valor                  AS valor,
       rec.departamentos.nome          AS departamento,
       pro.tiposligacaodepartamento.descricao AS tipo_ligacao,
       pro.departamentostiposrequerimento.valorparametro1,
       pro.departamentostiposrequerimento.valorparametro2,
       pro.departamentostiposrequerimento.tipoligacaodepartamento
FROM pro.tiposrequerimento,
     car.taxas,
     (SELECT *
      FROM (
               SELECT *,
                      RANK() OVER (PARTITION BY taxa ORDER BY inicio DESC) AS position
               FROM car.taxasprecos
           ) tx
      WHERE tx.position = 1) txprecos,
     pro.tiposreqdepartamentostiporeq,
     pro.departamentostiposrequerimento,
     pro.tiposligacaodepartamento,
     rec.departamentos
WHERE pro.tiposrequerimento.taxa IS NOT NULL
  AND pro.tiposrequerimento.status = 1
  AND car.taxas.codigo = pro.tiposrequerimento.taxa
  AND txprecos.taxa = car.taxas.codigo
  AND pro.tiposreqdepartamentostiporeq.tiporequerimento = pro.tiposrequerimento.codigo
  AND pro.departamentostiposrequerimento.codigo = pro.tiposreqdepartamentostiporeq.departamentotiporeq
  AND pro.tiposligacaodepartamento.codigo = pro.departamentostiposrequerimento.tipoligacaodepartamento
  AND rec.departamentos.codigo = pro.departamentostiposrequerimento.departamento;

ALTER TABLE tmp_protocolos_taxas
    ADD COLUMN parametro1 VARCHAR;

ALTER TABLE tmp_protocolos_taxas
    ADD COLUMN parametro2 VARCHAR;

UPDATE tmp_protocolos_taxas
SET parametro1 = tab.nomecurto
FROM bas.unidades tab
WHERE tab.codigo = tmp_protocolos_taxas.valorparametro1;

UPDATE tmp_protocolos_taxas
SET parametro2 = tab.nome
FROM gra.cursos tab
WHERE tab.codigo = tmp_protocolos_taxas.valorparametro2
  AND tmp_protocolos_taxas.tipoligacaodepartamento = 1;

UPDATE tmp_protocolos_taxas
SET parametro2 = tab.nome
FROM pos.cursos tab
WHERE tab.codigo = tmp_protocolos_taxas.valorparametro2
  AND tmp_protocolos_taxas.tipoligacaodepartamento = 3;

UPDATE tmp_protocolos_taxas
SET parametro2 = tab.nome
FROM mes.cursos tab
WHERE tab.codigo = tmp_protocolos_taxas.valorparametro2
  AND tmp_protocolos_taxas.tipoligacaodepartamento = 4;

SELECT codigo,
       requerimento,
       valor,
       tipo_ligacao,
       parametro1,
       parametro2,
       departamento
FROM tmp_protocolos_taxas
ORDER BY requerimento,
         parametro1,
         parametro2,
         departamento
