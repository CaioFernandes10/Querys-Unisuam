ROLLBACK;
DROP TABLE IF EXISTS tmp_emails_sanitizacao;
CREATE TEMPORARY TABLE tmp_emails_sanitizacao AS
SELECT codigo,
       endereco,
       '[' || endereco || ']'        AS email,
       bas.sp_valida_email(endereco) AS valido
FROM bas.emails;

DROP TABLE IF EXISTS tmp_emails_duplicados;
CREATE TEMPORARY TABLE tmp_emails_duplicados AS
SELECT endereco, email, valido, ARRAY_AGG(codigo) AS codigos
FROM tmp_emails_sanitizacao
GROUP BY 1, 2, 3;

SELECT *
FROM tmp_emails_duplicados;

/*
--COMMIT
ROLLBACK;
BEGIN;
DELETE FROM bas.pessoas_emails WHERE email in (SELECT codigo FROM tmp_emails_sanitizacao WHERE valido = FALSE);
DELETE FROM bas.empresas_emails WHERE email in (SELECT codigo FROM tmp_emails_sanitizacao WHERE valido = FALSE);
DELETE FROM bas.emails WHERE codigo in (SELECT codigo FROM tmp_emails_sanitizacao WHERE valido = FALSE);
*/

ALTER TABLE tmp_emails_duplicados
    ADD COLUMN pessoas INTEGER[];
ALTER TABLE tmp_emails_duplicados
    ADD COLUMN empresas INTEGER[];

UPDATE tmp_emails_duplicados
SET pessoas = dados.codigos
FROM (
         SELECT tmp_emails.endereco, ARRAY_AGG(DISTINCT emails.pessoa) AS codigos
         FROM tmp_emails_duplicados tmp_emails,
              bas.pessoas_emails emails
         WHERE emails.email = ANY(tmp_emails.codigos)
         GROUP BY 1
     ) dados
WHERE dados.endereco = tmp_emails_duplicados.endereco;


UPDATE tmp_emails_duplicados
SET empresas = dados.codigos
FROM (
         SELECT tmp_emails.endereco, ARRAY_AGG(DISTINCT emails.empresa) AS codigos
         FROM tmp_emails_duplicados tmp_emails,
              bas.empresas_emails emails
         WHERE emails.email = ANY(tmp_emails.codigos)
         GROUP BY 1
     ) dados
WHERE dados.endereco = tmp_emails_duplicados.endereco;

SELECT *
FROM tmp_emails_duplicados
WHERE ARRAY_UPPER(pessoas, 1) > 1;

/*
CREATE OR REPLACE FUNCTION bas.sp_valida_email(par_email VARCHAR)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
BEGIN
    RETURN UPPER(TRIM(par_email)) ~ '^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$';
END
$$;
GRANT EXECUTE ON FUNCTION bas.sp_valida_email(par_email VARCHAR) TO SAGA;

CREATE OR REPLACE FUNCTION bas.sp_trig_valida_email()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
BEGIN
    new.endereco := LOWER(TRIM(new.endereco));
    IF NOT bas.sp_valida_email(new.endereco) THEN
        RAISE EXCEPTION 'E-mail inválido para registro';
    END IF;
    RETURN new;
END
$$;

CREATE TRIGGER trig_boletos_before_update
    BEFORE INSERT OR UPDATE
    ON bas.emails
    FOR EACH ROW
EXECUTE PROCEDURE bas.sp_trig_valida_email();
*/