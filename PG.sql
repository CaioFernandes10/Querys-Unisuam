-- O = trigger fires in "origin" and "local" modes
-- D = trigger is disabled
-- R = trigger fires in "replica" mode
-- A = trigger fires always
SELECT *
FROM pg_trigger
WHERE tgrelid = 'car.boletos'::regclass;

SELECT pg_namespace.nspname, pg_class.relname, pg_trigger.*
FROM pg_trigger
JOIN pg_class ON pg_trigger.tgrelid = pg_class.oid
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace;

SELECT tablename,
       PG_SIZE_PRETTY(total_size)
FROM (
         SELECT table_schema || '.' || table_name                                         AS tablename,
                PG_TOTAL_RELATION_SIZE('"' || table_schema || '"."' || table_name || '"') AS total_size
         FROM information_schema.tables
         ORDER BY 2 DESC
         LIMIT 100
     ) tab;

DELETE
FROM hubspot.logs
WHERE created_at <= CURRENT_DATE - INTERVAL '3 months';

DELETE
FROM moodle.logs
WHERE created_at <= CURRENT_DATE - INTERVAL '6 months';

SELECT *
FROM avalia.logs
ORDER BY 1 DESC
LIMIT 100;


SELECT *
FROM web.logs
ORDER BY 1 DESC
LIMIT 100;

SELECT *
FROM crm.hubspot
ORDER BY 1 DESC
LIMIT 1000


