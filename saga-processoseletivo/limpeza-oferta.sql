
SELECT sel.objetivos.codigo, sel.objetivos.descricao, bas.unidades.nomesite
FROM sel.objetivos,
     bas.unidades,
     gra.turnos
WHERE sel.objetivos.processoseletivo = 320
  AND bas.unidades.codigo = sel.objetivos.valorparametro1
  AND gra.turnos.codigo = sel.objetivos.valorparametro4
  AND sel.objetivos.descricao || ' - ' || bas.unidades.nomesite
    IN ('Administração - Administração (Noite) - Centro',--13338
        'Administração - Administração (Noite) - Jacarepaguá', --13384
        'Licenciatura em Ciências Biológicas (Noite) - Bonsucesso', --13641
        'Ciências Contábeis (Manhã) - Bangu', --13436
        'Ciências Contábeis (Noite) - Centro', --13665
        'Engenharia Civil (Manhã) - Campo Grande', --13508
        'Engenharia de Produção (Manhã) - Campo Grande', --14136
        'Engenharia Elétrica (Noite) - Centro', --13666
        'Engenharia Mecânica (Noite) - Centro', --13667
        'Licenciatura em História (Noite) - Bonsucesso', --14139
        'Licenciatura em Pedagogia - Pedagogia (Noite) - Jacarepaguá',
        'Superior de Tecnologia em Análise e Desenvolvimento de Sistemas (Noite) - Jacarepaguá', --13400
        'Superior de Tecnologia em Design de Interiores (Manhã) - Bangu', --13461
        'Superior de Tecnologia em Design de Interiores (Noite) - Bangu', --13462
        'Superior de Tecnologia em Design de Interiores (Manhã) - Bonsucesso', --13652
        'Superior de Tecnologia em Design de Produto (Manhã) - Bonsucesso', --13654
        'Superior de Tecnologia em Design de Produto (Noite) - Bonsucesso', --13655
        'Superior de Tecnologia em Design Gráfico (Manhã) - Bonsucesso', --13656
        'Superior de Tecnologia em Gestão de Recursos Humanos (Noite) - Centro', --13364
        'Superior de Tecnologia em Logística (Noite) - Centro' --13376
          )
AND sel.objetivos.codigo NOT iN (SELECT objetivo FROM sel.opcoesinscricao);

ROLLBACK;
BEGIN;

ALTER TABLE sel.objetivos DISABLE TRIGGER trig_objetivos_before_delete;
ALTER TABLE sel.fasesobjetivosprovas DISABLE TRIGGER trig_fasesobjetivosprovas_before_delete;
ALTER TABLE sel.objetivosocorrencias DISABLE TRIGGER trig_objetivosocorrencias_before_delete;

DELETE FROM sel.objetivosocorrencias WHERE objetivo IN (13667, 13666, 13665, 14136, 13508, 13656, 13655, 13654, 13652, 14139, 13641, 13338, 13364, 13376, 13384, 13396, 13400, 13436, 13461, 13462);
DELETE FROM sel.fasesobjetivosprovas WHERE objetivo IN (13667, 13666, 13665, 14136, 13508, 13656, 13655, 13654, 13652, 14139, 13641, 13338, 13364, 13376, 13384, 13396, 13400, 13436, 13461, 13462);
DELETE FROM sel.objetivos WHERE codigo IN (13667, 13666, 13665, 14136, 13508, 13656, 13655, 13654, 13652, 14139, 13641, 13338, 13364, 13376, 13384, 13396, 13400, 13436, 13461, 13462);

ALTER TABLE sel.objetivos ENABLE TRIGGER trig_objetivos_before_delete;
ALTER TABLE sel.fasesobjetivosprovas ENABLE TRIGGER trig_fasesobjetivosprovas_before_delete;
ALTER TABLE sel.objetivosocorrencias ENABLE TRIGGER trig_objetivosocorrencias_before_delete;

--