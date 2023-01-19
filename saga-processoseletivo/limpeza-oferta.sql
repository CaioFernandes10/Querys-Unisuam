
SELECT sel.objetivos.codigo, sel.objetivos.descricao, bas.unidades.nomesite
FROM sel.objetivos,
     bas.unidades,
     gra.turnos
WHERE sel.objetivos.processoseletivo = 320
  AND bas.unidades.codigo = sel.objetivos.valorparametro1
  AND gra.turnos.codigo = sel.objetivos.valorparametro4
  AND sel.objetivos.descricao || ' - ' || bas.unidades.nomesite
    IN ('Administra��o - Administra��o (Noite) - Centro',--13338
        'Administra��o - Administra��o (Noite) - Jacarepagu�', --13384
        'Licenciatura em Ci�ncias Biol�gicas (Noite) - Bonsucesso', --13641
        'Ci�ncias Cont�beis (Manh�) - Bangu', --13436
        'Ci�ncias Cont�beis (Noite) - Centro', --13665
        'Engenharia Civil (Manh�) - Campo Grande', --13508
        'Engenharia de Produ��o (Manh�) - Campo Grande', --14136
        'Engenharia El�trica (Noite) - Centro', --13666
        'Engenharia Mec�nica (Noite) - Centro', --13667
        'Licenciatura em Hist�ria (Noite) - Bonsucesso', --14139
        'Licenciatura em Pedagogia - Pedagogia (Noite) - Jacarepagu�',
        'Superior de Tecnologia em An�lise e Desenvolvimento de Sistemas (Noite) - Jacarepagu�', --13400
        'Superior de Tecnologia em Design de Interiores (Manh�) - Bangu', --13461
        'Superior de Tecnologia em Design de Interiores (Noite) - Bangu', --13462
        'Superior de Tecnologia em Design de Interiores (Manh�) - Bonsucesso', --13652
        'Superior de Tecnologia em Design de Produto (Manh�) - Bonsucesso', --13654
        'Superior de Tecnologia em Design de Produto (Noite) - Bonsucesso', --13655
        'Superior de Tecnologia em Design Gr�fico (Manh�) - Bonsucesso', --13656
        'Superior de Tecnologia em Gest�o de Recursos Humanos (Noite) - Centro', --13364
        'Superior de Tecnologia em Log�stica (Noite) - Centro' --13376
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