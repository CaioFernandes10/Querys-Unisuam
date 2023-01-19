SELECT TO_CHAR(sel.inscricoes.dataregistro, 'YYYY-MM-DD HH24') AS datahora,
       COUNT(*)                                                AS inscricoes
FROM sel.fases,
     sel.inscricoesfases,
     sel.inscricoes
WHERE sel.fases.ocorrencia = 36123
  AND sel.inscricoesfases.fase = sel.fases.codigo
  AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
GROUP BY 1
UNION
SELECT TO_CHAR(sel.inscricoes.dataregistro, 'YYYY-MM-DD') AS datahora,
       COUNT(*)                                           AS inscricoes
FROM sel.fases,
     sel.inscricoesfases,
     sel.inscricoes
WHERE sel.fases.ocorrencia = 36123
  AND sel.inscricoesfases.fase = sel.fases.codigo
  AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
GROUP BY 1
UNION
SELECT 'TOTAL'  AS datahora,
       COUNT(*) AS inscricoes
FROM sel.fases,
     sel.inscricoesfases,
     sel.inscricoes
WHERE sel.fases.ocorrencia = 36123
  AND sel.inscricoesfases.fase = sel.fases.codigo
  AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
GROUP BY 1
ORDER BY 1;

SELECT sel.inscricoes.pessoa,
       COUNT(*) AS inscricoes
FROM sel.fases,
     sel.inscricoesfases,
     sel.inscricoes
WHERE sel.fases.ocorrencia = 36123
  AND sel.inscricoesfases.fase = sel.fases.codigo
  AND sel.inscricoes.codigo = sel.inscricoesfases.inscricao
GROUP BY 1
HAVING COUNT(*) > 1;