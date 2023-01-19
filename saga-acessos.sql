SELECT bas.pessoas.nome,
       sis.usuarios.login,
       'usuario'                                                AS grupo,
       sis.sp_retornacaminhorecurso(sis.recursos.codigo, ' > ') AS recurso,
       ur.bloqueado,
       sis.usuarios.ativo,
       sis.usuarios.setor
FROM sis.usuarios_recursos ur
JOIN sis.usuarios ON sis.usuarios.codigo = ur.usuario
JOIN bas.pessoas ON bas.pessoas.codigo = sis.usuarios.pessoa
JOIN sis.recursos ON sis.recursos.codigo = ur.recurso
WHERE TRUE
  AND sis.recursos.codigo IN (1154)
  --AND ur.bloqueado = FALSE
  AND sis.usuarios.ativo = TRUE
--and sis.usuarios.especial = true
--  AND sis.usuarios.login IN ('1001506')

UNION

SELECT bas.pessoas.nome,
       sis.usuarios.login,
       sis.grupos.label,
       sis.sp_retornacaminhorecurso(sis.recursos.codigo, ' > ') AS recurso,
       FALSE                                                    AS bloqueado,
       sis.usuarios.ativo,
       sis.usuarios.setor
FROM sis.grupos_recursos
LEFT JOIN sis.grupos_usuarios ON sis.grupos_usuarios.grupo = sis.grupos_recursos.grupo
LEFT JOIN sis.usuarios ON sis.usuarios.codigo = sis.grupos_usuarios.usuario
LEFT JOIN bas.pessoas ON bas.pessoas.codigo = sis.usuarios.pessoa
JOIN sis.grupos ON sis.grupos.codigo = sis.grupos_recursos.grupo
JOIN sis.recursos ON sis.recursos.codigo = sis.grupos_recursos.recurso
WHERE TRUE
  AND sis.recursos.codigo IN (1154)
  --AND sis.grupos_recursos.bloqueado = FALSE
  AND sis.usuarios.ativo = TRUE
--AND sis.usuarios.login IN ('1001806')
--and sis.grupos.label = 'FIN NEG GESTÃO'
--and sis.grupos.codigo not IN (1194,1189)
ORDER BY 1, 2, 3, 4
