--ROLLBACK;
SELECT ARRAY_AGG(codigo)
FROM (
         SELECT sis.operacoes.*,
                t1.nome AS tabela_parametro1,
                t2.nome AS tabela_parametro2,
                t3.nome AS tabela_parametro3,
                t4.nome AS tabela_parametro4,
                t5.nome AS tabela_parametro5,
                t6.nome AS tabela_parametro6
         FROM sis.operacoes
         LEFT JOIN sis.tabelas t1 ON t1.codigo = sis.operacoes.parametro1
         LEFT JOIN sis.tabelas t2 ON t2.codigo = sis.operacoes.parametro2
         LEFT JOIN sis.tabelas t3 ON t3.codigo = sis.operacoes.parametro3
         LEFT JOIN sis.tabelas t4 ON t4.codigo = sis.operacoes.parametro4
         LEFT JOIN sis.tabelas t5 ON t5.codigo = sis.operacoes.parametro5
         LEFT JOIN sis.tabelas t6 ON t6.codigo = sis.operacoes.parametro6
         WHERE 'bas.documentos' IN (t1.nome, t2.nome, t3.nome, t4.nome, t5.nome, t6.nome)
         --WHERE sis.operacoes.codigo = 2241
         --WHERE sis.operacoes.codigo IN (1454,1453,2267)
     ) operacoes;

SELECT *
FROM sis.logs
WHERE operacao IN (142,143,144,145,146,194,195)
  --AND instrucaosql ILIKE '%5117%'
--and parametro1 = 1374
ORDER BY 1 DESC
LIMIT 1000;



SELECT sis.usuarios.login,
       bas.pessoas.nome,
       sis.logs.dataehora,
       sis.operacoes.descricao
FROM sis.logs,
     sis.usuarios,
     bas.pessoas,
     sis.operacoes
WHERE sis.logs.operacao IN (1355, 1356, 1357)
  AND sis.logs.instrucaosql ILIKE '%5117%'
  AND sis.usuarios.codigo = sis.logs.usuario
  AND bas.pessoas.codigo = sis.usuarios.pessoa
AND sis.operacoes.codigo = sis.logs.operacao
ORDER BY sis.logs.codigo



