--COMMIT;
ROLLBACK;
BEGIN;

DROP TABLE IF EXISTS tmp_enviar_email;
CREATE TEMPORARY TABLE tmp_enviar_email
(
    email               VARCHAR,
    assunto             VARCHAR,
    lista_de_documentos VARCHAR,
    processamento       VARCHAR
);

DO
$$
    DECLARE
        rec_comunicacao          RECORD;
        rec_documentos_pendentes RECORD;
        var_corpo                VARCHAR;
        var_titulo               VARCHAR;
        var_documentos           VARCHAR;
    BEGIN

        SELECT * FROM com.comunicacoes WHERE codigo = 33 INTO rec_comunicacao;

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

        FOR rec_documentos_pendentes IN
            SELECT doc.pessoa_id,
                   doc.requerimento_id,
                   SPLIT_PART(bas.pessoas.nome, ' ', 1)                               AS nome,
                   bas.sp_google(bas.pessoas.codigo)                                  AS email,
                   (STRING_AGG(DISTINCT det.documento, '|@|' ORDER BY det.documento)) AS documentos
            FROM tmp_pendencias_documentos doc
            LEFT JOIN tmp_pendencias_documentos_detalhes det ON det.pessoa_id = doc.pessoa_id
            JOIN bas.pessoas ON bas.pessoas.codigo = doc.pessoa_id
            WHERE det.pessoa_id IS NOT NULL
            GROUP BY 1, 2, 3, 4
        LOOP

            var_documentos := REPLACE(rec_documentos_pendentes.documentos, '|@|', '<br>');
            var_corpo := REPLACE(rec_comunicacao.corpo, '[NOME]', rec_documentos_pendentes.nome);
            var_corpo := REPLACE(var_corpo, '[LISTA_DOCUMENTOS]', var_documentos);
            var_titulo := REPLACE(rec_comunicacao.titulo, '[NOME]', rec_documentos_pendentes.nome);

            IF rec_documentos_pendentes.email IS NOT NULL THEN
                INSERT INTO sis.emailbatch (destinatario, assunto, mensagem)
                VALUES (rec_documentos_pendentes.email, var_titulo, var_corpo);
            END IF;

            /*
            SELECT codigo
            FROM sis.emailbatch
            WHERE destinatario = rec_documentos_pendentes.email
              AND assunto = var_titulo
            INTO var_retorno;

            INSERT INTO tmp_enviar_email (email, assunto, lista_de_documentos, processamento)
            VALUES (rec_documentos_pendentes.email, var_titulo, var_documentos,
                    CASE WHEN var_retorno IS NOT NULL THEN 'FOI' ELSE 'NÃO FOI' END);
            */

        END LOOP;


    END;

$$;

SELECT *
FROM tmp_enviar_email;


SELECT *
FROM sis.emailbatch
WHERE assunto ~* 'você possui documentos pendentes!'
  AND dataregistro::DATE = '2021-12-07';