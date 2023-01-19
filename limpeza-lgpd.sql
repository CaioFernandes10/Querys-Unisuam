-- LIMPEZA GERAL LGPD
-- -> APAGANDO EMAILS
-- -> APAGANDO DOCUMENTOS
-- -> APAGANDO TELEFONES
-- -> APAGANDO ENDERECOS
-- -> APAGANDO HUBSPOT NEGOCIOS / CONTATOS
-- -> APAGANDO HEP FLUXOS / DETALHES
-- -> LIMPEZA DE DADOS PESSOAIS E HASH NO NOME
-- -> DASHBOARD CAPTAÇÃO (LIMPEZA DE DADOS E HASH NO NOME)
-- -> DASHBOARD ANALYTICS (LIMPEZA DE DADOS E HASH NO NOME)
-- ??? DASHBOARD ANTIGOS ???

--COMMIT
ROLLBACK;
BEGIN;

DO
$$
    DECLARE
        par_email           VARCHAR := 'raissapds16@gmail.com';
        rec_pessoa          RECORD;
        int_pessoa          INTEGER;
        var_cpf             VARCHAR;
        int_email           INTEGER;
        int_telefone        INTEGER;
        int_documento       INTEGER;
        int_endereco        INTEGER;
        int_hubspot_contato INTEGER;
        int_hubspot_negocio INTEGER;
        int_hep_fluxos      INTEGER;
        int_hep_detalhes    INTEGER;
    BEGIN

        FOR rec_pessoa IN
            SELECT pessoa, bas.sp_cpf(pessoa, FALSE) AS cpf
            FROM bas.emails,
                 bas.pessoas_emails
            WHERE TRIM(LOWER(bas.emails.endereco)) = par_email
              AND bas.pessoas_emails.email = bas.emails.codigo
        LOOP

            int_pessoa := rec_pessoa.pessoa;
            var_cpf := rec_pessoa.cpf;

            RAISE NOTICE '# PESSOA => % / %', int_pessoa, var_cpf;

            FOR int_email IN
                SELECT pessoa
                FROM bas.pessoas_emails
                WHERE pessoa = int_pessoa
            LOOP
                RAISE NOTICE '# DELETANDO EMAIL';
                DELETE FROM bas.pessoas_emails WHERE email = int_email;
                DELETE FROM bas.emails WHERE codigo = int_email;
            END LOOP;

            FOR int_documento IN
                SELECT documento
                FROM bas.pessoas_documentos
                WHERE pessoa = int_pessoa
            LOOP
                RAISE NOTICE '# DELETANDO DOCUMENTO';
                DELETE FROM bas.pessoas_documentos WHERE documento = int_documento;
                DELETE FROM bas.documentos WHERE codigo = int_documento;
            END LOOP;

            FOR int_telefone IN
                SELECT telefone
                FROM bas.pessoas_telefones
                WHERE pessoa = int_pessoa
            LOOP
                RAISE NOTICE '# DELETANDO TELEFONE';
                DELETE FROM bas.pessoas_telefones WHERE telefone = int_telefone;
                DELETE FROM bas.telefones WHERE codigo = int_telefone;
            END LOOP;

            FOR int_endereco IN
                SELECT endereco
                FROM bas.pessoas_enderecos
                WHERE pessoa = int_pessoa
            LOOP
                RAISE NOTICE '# DELETANDO ENDERECO';
                DELETE FROM bas.pessoas_enderecos WHERE endereco = int_endereco;
                DELETE FROM bas.enderecos WHERE codigo = int_endereco;
            END LOOP;

            FOR int_hubspot_contato IN
                SELECT id
                FROM hubspot.contatos
                WHERE pessoa_id = int_pessoa
            LOOP
                FOR int_hubspot_negocio IN
                    SELECT id
                    FROM hubspot.negocios
                    WHERE contato_id = int_hubspot_contato
                LOOP
                    RAISE NOTICE '# DELETANDO HUBSPOT - NEGOCIOS';
                    DELETE FROM hubspot.negocios WHERE id = int_hubspot_negocio;
                END LOOP;
                RAISE NOTICE '# DELETANDO HUBSPOT - CONTATOS';
                DELETE FROM hubspot.contatos WHERE id = int_hubspot_contato;
            END LOOP;

            FOR int_hep_fluxos IN
                SELECT id
                FROM hep.fluxos
                WHERE pessoa_id = int_pessoa
            LOOP
                FOR int_hep_detalhes IN
                    SELECT id
                    FROM hep.fluxosdetalhes
                    WHERE fluxo_id = int_hep_fluxos
                LOOP
                    RAISE NOTICE '# DELETANDO HEP - DETALHES';
                    DELETE FROM hep.fluxosdetalhes WHERE id = int_hep_detalhes;
                END LOOP;
                RAISE NOTICE '# DELETANDO HEP - FLUXOS';
                DELETE FROM hep.fluxos WHERE id = int_hep_fluxos;
            END LOOP;

            UPDATE bas.pessoas
            SET nome             = MD5(nome),
                nomesimples      = MD5(nomesimples),
                estadocivil      = NULL,
                militarsituacao  = NULL,
                nascimentopais   = NULL,
                nascimentoestado = NULL,
                nascimentocidade = NULL,
                nascimentodata   = NULL,
                sexo             = NULL,
                situacaomilitar  = NULL,
                senha            = NULL,
                nomepai          = NULL,
                nomemae          = NULL,
                foto             = NULL,
                etnia            = NULL,
                nomereceita      = NULL,
                mbti             = NULL,
                apelido          = NULL
            WHERE codigo = int_pessoa;
            RAISE NOTICE '# HASHEANDO DADOS DA PESSOA %', int_pessoa;

            RAISE NOTICE '# LIMPANDO DADOS DASHBOARD CAPTAÇAO';
            PERFORM DBLINK_CONNECT_U('dbname=dashboard host=127.0.0.1 user=postgres password= port=5432');
            PERFORM public.dblink('BEGIN;
                UPDATE gerencial.db_pessoas
                SET cpf = ''ID''||''' || int_pessoa || ''',
                    nome = MD5(nome),
                    nascimentodata = NULL,
                    nomerf = NULL,
                    nomemae = NULL,
                    nomepai = NULL,
                    sexo_label = NULL,
                    sexo = NULL,
                    etnia = NULL,
                    estadocivil = NULL,
                    militarsituacao = NULL,
                    telefones = NULL,
                    celular = NULL,
                    liveedu = NULL,
                    emails = NULL,
                    endereco_logradouro = NULL,
                    endereco_bairro = NULL,
                    endereco_cidade = NULL,
                    endereco_estado = NULL,
                    endereco_pais = NULL,
                    endereco_numero = NULL,
                    endereco_complemento = NULL,
                    endereco_cep = NULL,
                    pessoa_id = NULL,
                    nascimentopais_id = NULL,
                    nascimentoestado_id = NULL,
                    nascimentocidade_id = NULL,
                    etnia_id = NULL,
                    estadocivil_id = NULL,
                    militarsituacao_id = NULL,
                    endereco_id = NULL
                WHERE cpf = ''' || var_cpf || ''';

                UPDATE gerencial.db_captacao_alunos
                SET cpf = ''ID''||''' || int_pessoa || '''
                WHERE cpf = ''' || var_cpf || ''';

                UPDATE gerencial.db_pos_captacao_alunos
                SET cpf = ''ID''||''' || int_pessoa || '''
                WHERE cpf = ''' || var_cpf || ''';
            ');
            PERFORM DBLINK_DISCONNECT();

            RAISE NOTICE '# LIMPANDO DADOS DASHBOARD ANALYTICS';
            PERFORM DBLINK_CONNECT_U('dbname=analytics host=10.0.101.132 user=postgres password= port=5432');
            PERFORM public.dblink('BEGIN;
                UPDATE graduacao.ingressantes
                SET cpf = ''ID''||''' || int_pessoa || '''
                WHERE cpf = ''' || var_cpf || ''';

                UPDATE graduacao.veteranos
                SET cpf = ''ID''||''' || int_pessoa || '''
                WHERE cpf = ''' || var_cpf || ''';
            ');
            PERFORM DBLINK_DISCONNECT();

        END LOOP;
    END
$$;

--# PESSOA => 588315 / 19737302788

