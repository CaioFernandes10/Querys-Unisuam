DROP TABLE IF EXISTS tmp_inclusao_encaminhamento_em_massa;
CREATE TABLE tmp_inclusao_encaminhamento_em_massa
(
    protocolo       VARCHAR,
    protocolo_id    INTEGER,
    requerimento_id INTEGER,
    status_id       INTEGER,
    usuario_id      INTEGER,
    departamento_id INTEGER,
    parecer_interno TEXT,
    parecer_externo TEXT
);

INSERT INTO tmp_inclusao_encaminhamento_em_massa (protocolo)
VALUES ('101741781.2'),
       ('101741781.1'),
       ('101742118.2'),
       ('101742118.1'),
       ('101741903.2'),
       ('101741903.1'),
       ('101742121.2'),
       ('101742121.1'),
       ('101742124.2'),
       ('101742124.1'),
       ('101741904.2'),
       ('101741904.1'),
       ('101742056.2'),
       ('101742056.1'),
       ('101742053.2'),
       ('101742053.1'),
       ('101742054.2'),
       ('101742054.1'),
       ('101742090.2'),
       ('101742090.1'),
       ('101742089.2'),
       ('101742089.1'),
       ('101742123.2'),
       ('101742123.1'),
       ('101742129.2'),
       ('101742129.1'),
       ('101742130.2'),
       ('101742130.1'),
       ('101742109.2'),
       ('101742109.1'),
       ('101747141.2'),
       ('101747141.1'),
       ('101747128.2'),
       ('101747128.1'),
       ('101747127.2'),
       ('101747127.1'),
       ('101747119.2'),
       ('101747119.1'),
       ('101747125.2'),
       ('101747125.1'),
       ('101747122.2'),
       ('101747122.1'),
       ('101747137.2'),
       ('101747137.1'),
       ('101747136.2'),
       ('101747136.1'),
       ('101747133.2'),
       ('101747133.1'),
       ('101747134.2'),
       ('101747134.1'),
       ('101747155.2'),
       ('101747155.1'),
       ('101747154.2'),
       ('101747154.1'),
       ('101747151.2'),
       ('101747151.1'),
       ('101747150.2'),
       ('101747150.1'),
       ('101742132.2'),
       ('101742132.1'),
       ('101735155.1'),
       ('101747158.2'),
       ('101747158.1'),
       ('101747157.2'),
       ('101747157.1'),
       ('101747181.2'),
       ('101747181.1'),
       ('101747178.2'),
       ('101747178.1'),
       ('101747161.2'),
       ('101747161.1'),
       ('101747134.2'),
       ('101747134.1'),
       ('101747131.2'),
       ('101747131.1'),
       ('101747130.2'),
       ('101747130.1'),
       ('101747129.2'),
       ('101747129.1'),
       ('101747173.2'),
       ('101747173.1'),
       ('101747170.2'),
       ('101747170.1'),
       ('101747169.2'),
       ('101747169.1'),
       ('101714786.1'),
       ('101760725.2'),
       ('101760725.1'),
       ('101747187.2'),
       ('101747187.1'),
       ('101747107.2'),
       ('101747107.1'),
       ('101770860.2'),
       ('101770860.1'),
       ('101747189.2'),
       ('101747189.1'),
       ('101747188.2'),
       ('101747188.1'),
       ('101747176.2'),
       ('101747176.1'),
       ('101747174.2'),
       ('101747174.1'),
       ('101747184.2'),
       ('101747184.1'),
       ('101747185.2'),
       ('101747185.1'),
       ('101747140.2'),
       ('101747140.1'),
       ('101749265.2'),
       ('101749265.1'),
       ('101747196.2'),
       ('101747196.1'),
       ('101747191.2'),
       ('101747191.1'),
       ('101747195.2'),
       ('101747195.1'),
       ('101747193.2'),
       ('101747193.1'),
       ('101747192.2'),
       ('101747192.1'),
       ('101747267.2'),
       ('101747267.1'),
       ('101747204.2'),
       ('101747204.1'),
       ('101747214.2'),
       ('101747214.1'),
       ('101747203.2'),
       ('101747203.1'),
       ('101747205.2'),
       ('101747205.1'),
       ('101678131.1'),
       ('101757826.1'),
       ('101747182.2'),
       ('101747182.1'),
       ('101747175.2'),
       ('101747175.1');

UPDATE tmp_inclusao_encaminhamento_em_massa
SET protocolo_id    = pro.requerimentos.protocolo,
    requerimento_id = pro.requerimentos.codigo
FROM pro.protocolos,
     pro.requerimentos
WHERE pro.requerimentos.protocolo = pro.protocolos.codigo
  AND pro.protocolos.label = SPLIT_PART(tmp_inclusao_encaminhamento_em_massa.protocolo, '.', 1)
  AND pro.requerimentos.ordem = SPLIT_PART(tmp_inclusao_encaminhamento_em_massa.protocolo, '.', 2);


UPDATE tmp_inclusao_encaminhamento_em_massa
SET usuario_id      = 5,
    departamento_id = 543,
    status_id       = 7,
    parecer_externo = 'Seu documento encontra-se disponível. Setor Central de Relacionamento - Unidade Bonsucesso. Ele poderá ser retirado das 9h até 17h30 de segunda a sexta.',
    parecer_interno = 'Seu documento encontra-se disponível. Setor Central de Relacionamento - Unidade Bonsucesso. Ele poderá ser retirado das 9h até 17h30 de segunda a sexta.'
WHERE TRUE;


SELECT *
FROM tmp_inclusao_encaminhamento_em_massa;


/*
ROLLBACK;
DROP TABLE IF EXISTS temp_tbl;
CREATE TEMPORARY TABLE temp_tbl (
  usuario INTEGER, programa INTEGER, ipinterno VARCHAR, ipexterno VARCHAR,
  tabela VARCHAR, operacao INTEGER, tipo VARCHAR, sql VARCHAR,
  valorparametro1 INTEGER, valorparametro2 INTEGER, valorparametro3 INTEGER,
  valorparametro4 INTEGER, valorparametro5 INTEGER, valorparametro6 INTEGER
);
DELETE FROM temp_tbl WHERE TRUE;
INSERT INTO temp_tbl (usuario, programa, ipinterno, ipexterno) VALUES (5, 8, '', '');
UPDATE temp_tbl SET operacao = 590, tabela = 'pro.encaminhamentos', tipo = 'I', sql = '--Operação Manual--' WHERE TRUE;
*/

--COMMIT
ROLLBACK;
BEGIN;

INSERT INTO pro.encaminhamentos (status, requerimento, usuario, parecerinterno, parecerexterno, departamento)
SELECT tmp_inclusao_encaminhamento_em_massa.status_id,
       tmp_inclusao_encaminhamento_em_massa.requerimento_id,
       tmp_inclusao_encaminhamento_em_massa.usuario_id,
       tmp_inclusao_encaminhamento_em_massa.parecer_interno,
       tmp_inclusao_encaminhamento_em_massa.parecer_externo,
       tmp_inclusao_encaminhamento_em_massa.departamento_id
FROM tmp_inclusao_encaminhamento_em_massa;


SELECT *
FROM tmp_inclusao_encaminhamento_em_massa;