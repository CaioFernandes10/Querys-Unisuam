--cursos-disciplinas-hep
SELECT pos.cursos.nome            AS curso,
       pos.estruturas.label       AS curso_id,
       pos.modulos.label::VARCHAR AS modulo,
       pos.disciplinas.label      AS disciplina_id,
       pos.disciplinas.nome       AS disciplina
FROM pos.cursos,
     pos.estruturas,
     pos.estruturasdetalhes,
     pos.modulos,
     pos.disciplinas
WHERE pos.estruturas.curso = pos.cursos.codigo
  AND pos.estruturasdetalhes.estrutura = pos.estruturas.codigo
  AND pos.modulos.codigo = pos.estruturasdetalhes.modulo
  AND pos.disciplinas.codigo = pos.estruturasdetalhes.disciplina
  AND pos.estruturas.label
    IN ('MDI001', 'GMA001', 'GVE001', 'BIG001', 'IOS001', 'DIG001', 'QPS001',
        'CHA001', 'COA001', 'CHL001', 'GFC001', 'AEC001', 'MEA001', 'GPB001',
        'GHO001', 'IEF001', 'GCP001', 'GOE001', 'INC001', 'PEE001', 'CLI001',
        'ZAG001', 'PRE001', 'MAA001', 'EAD001', 'INO001', 'UDE001', 'MAG001',
        'ESF001', 'SAU001')
ORDER BY 1, 3, 5;


