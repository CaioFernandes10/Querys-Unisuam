DROP FUNCTION IF EXISTS sis.sp_embaralha_texto(par_string VARCHAR);
CREATE FUNCTION sis.sp_embaralha_texto(par_string VARCHAR)
    RETURNS VARCHAR
    LANGUAGE plpgsql AS
$$
DECLARE
    new_char   CHAR;
    new_string VARCHAR := '';
BEGIN
    FOR j IN 1..LENGTH(par_string)
    LOOP
        new_char := SUBSTR(par_string, j, 1);
        IF new_char NOT IN (' ', '.', '@','-')
            AND j != 1
            AND (ROUND(RANDOM())::INT)::BOOLEAN
        THEN
            new_char := '*';
        END IF;
        new_string := CONCAT(new_string, new_char);
    END LOOP;
    RETURN new_string;
END
$$;

GRANT EXECUTE ON FUNCTION sis.sp_embaralha_texto(par_string VARCHAR) TO saga;


SELECT sis.sp_embaralha_texto('joao roberto almeida'),
        sis.sp_embaralha_texto('joaorca@gmail.com'),
        sis.sp_embaralha_texto('097.969.637-28')
