CREATE OR REPLACE FUNCTION ext.sp_tipoprereq25(par_aluno INTEGER, par_disciplina INTEGER) RETURNS SETOF ext.retprerequisito
    LANGUAGE plpgsql
AS
$$
DECLARE
    rec_retorno                                      ext.retprerequisito;
    rec_aluno                                        RECORD;
    rec_disciplina                                   RECORD;
    rec_inscricoes                                   RECORD;
    rec_prequisitos                                  RECORD;
    int_modalidade_curso_ferias                      INTEGER := 1080;
    int_atividade_pai                                INTEGER := 21598;
    arr_disciplinas_emcurso_ferias                   INTEGER[];
    bool_podecursar                                  BOOLEAN := FALSE;
    bool_disciplina_institucional                    BOOLEAN := FALSE;
    num_disciplinas_institucionais                   INTEGER := 0;
    num_disciplinas_naoinstitucionais_sem_quebra     INTEGER := 0;
    num_disciplinas_naoinstitucionais_com_quebra     INTEGER := 0;
    num_max_disciplinas_institucionais               INTEGER := 0;
    num_max_disciplinas_naoinstitucionais_sem_quebra INTEGER := 5;
    num_max_disciplinas_naoinstitucionais_com_quebra INTEGER := 0;
BEGIN

    RAISE NOTICE '==============================================================================================';

    ----------------------------------------------------------------------------------------------------------------
    /* validando para com o dado do aluno */
    ----------------------------------------------------------------------------------------------------------------
    IF par_aluno IS NULL THEN
        rec_retorno.erro := TRUE;
        rec_retorno.textoerro := 'Código do aluno da extensão não informado.';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;
    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    /* validando se o id do aluno informado existe */
    ----------------------------------------------------------------------------------------------------------------
    SELECT codigo, label, pessoa
    FROM ext.alunos
    WHERE codigo = par_aluno
    INTO rec_aluno;

    IF NOT found THEN
        rec_retorno.erro := TRUE;
        rec_retorno.textoerro := 'Código do aluno informado não é válido.';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;
    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    /* validando parametro com o dado da disciplina */
    ----------------------------------------------------------------------------------------------------------------
    IF par_disciplina IS NULL THEN
        rec_retorno.erro := TRUE;
        rec_retorno.textoerro := 'Código da disciplina não informado.';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;
    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    /* validando se o id da disciplina informada existe */
    ----------------------------------------------------------------------------------------------------------------
    SELECT codigo, label, nome
    FROM gra.disciplinas
    WHERE codigo = par_disciplina
    INTO rec_disciplina;

    IF NOT found THEN
        rec_retorno.erro := TRUE;
        rec_retorno.textoerro := 'Código da disciplina informado não é válido.';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;
    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    /* validando se o aluno vai se formar antes do tempo */
    ----------------------------------------------------------------------------------------------------------------
    SELECT ARRAY_AGG(ext.prerequisitos.parametro)
    FROM ext.atividades,
         ext.turmas,
         ext.periodosletivos,
         ext.matriculas,
         ext.prerequisitos
    WHERE ext.atividades.modalidade = int_modalidade_curso_ferias
      AND ext.turmas.atividade = ext.atividades.codigo
      AND ext.periodosletivos.codigo = ext.turmas.periodoletivo
      AND ext.atividades.atividadepai = int_atividade_pai
      AND ext.matriculas.turma = ext.turmas.codigo
      AND ext.matriculas.aluno = par_aluno
      AND ext.matriculas.status IN (1, 2)
      AND ext.prerequisitos.turma = ext.turmas.codigo
    INTO arr_disciplinas_emcurso_ferias;

    arr_disciplinas_emcurso_ferias := ARRAY_APPEND(arr_disciplinas_emcurso_ferias, par_disciplina);

    SELECT gra.sp_verifica_disciplina_curso_ferias_periodos_cursados(
                   rec_aluno.pessoa,
                   arr_disciplinas_emcurso_ferias)
    INTO bool_podecursar;

    IF NOT bool_podecursar THEN
        rec_retorno.erro := FALSE;
        rec_retorno.cumpriu := FALSE;
        rec_retorno.textolivre := 'O aluno não pode cursar a disciplina "' || rec_disciplina.nome || '" (#01).';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;
    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    /* atualizando contadores de inscricoes  */
    ----------------------------------------------------------------------------------------------------------------
    FOR rec_inscricoes IN
        SELECT ext.turmas.codigo AS turma_id
        FROM ext.atividades,
             ext.turmas,
             ext.periodosletivos,
             ext.matriculas
        WHERE ext.atividades.modalidade = int_modalidade_curso_ferias
          AND ext.turmas.atividade = ext.atividades.codigo
          AND ext.periodosletivos.codigo = ext.turmas.periodoletivo
          AND ext.atividades.atividadepai = int_atividade_pai
          AND ext.matriculas.turma = ext.turmas.codigo
          AND ext.matriculas.aluno = par_aluno
          AND ext.matriculas.status IN (1, 2)
    LOOP
        bool_disciplina_institucional := FALSE;
        bool_podecursar := FALSE;

        FOR rec_prequisitos IN
            SELECT gra.disciplinas.codigo      AS disciplina_id,
                   gra.disciplinas.label       AS disciplina_label,
                   gra.disciplinas.nomesimples AS disciplina_nome
            FROM ext.prerequisitos,
                 gra.disciplinas
            WHERE ext.prerequisitos.turma = rec_inscricoes.turma_id
              AND gra.disciplinas.codigo = ext.prerequisitos.parametro
        LOOP
            bool_disciplina_institucional := FALSE;
            --bool_disciplina_institucional := SUBSTRING(rec_prequisitos.disciplina_label, 1, 4) = 'GINS';
            BEGIN
                SELECT gra.sp_verifica_disciplina_curso_ferias(
                               rec_aluno.pessoa,
                               rec_prequisitos.disciplina_id::INTEGER)
                INTO bool_podecursar;
            EXCEPTION
                WHEN OTHERS THEN bool_podecursar := FALSE;
            END;
            IF bool_podecursar THEN EXIT; END IF;
        END LOOP;

        RAISE NOTICE '------------------bool_disciplina_institucional:%',bool_disciplina_institucional;
        RAISE NOTICE '------------------bool_podecursar:%',bool_podecursar;

        IF bool_disciplina_institucional THEN
            num_disciplinas_institucionais := num_disciplinas_institucionais + 1;
            CONTINUE;
        END IF;
        IF bool_podecursar THEN
            num_disciplinas_naoinstitucionais_sem_quebra := num_disciplinas_naoinstitucionais_sem_quebra + 1;
            CONTINUE;
        END IF;
        num_disciplinas_naoinstitucionais_com_quebra := num_disciplinas_naoinstitucionais_com_quebra + 1;

    END LOOP;

    RAISE NOTICE '----------------------------------';
    RAISE NOTICE 'num_disciplinas_institucionais:%',num_disciplinas_institucionais;
    RAISE NOTICE 'num_disciplinas_naoinstitucionais_sem_quebra:%',num_disciplinas_naoinstitucionais_sem_quebra;
    RAISE NOTICE 'num_disciplinas_naoinstitucionais_com_quebra:%',num_disciplinas_naoinstitucionais_com_quebra;
    RAISE NOTICE '----------------------------------';
    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    /* validando a inscricao na disciplina informada */
    ----------------------------------------------------------------------------------------------------------------
    BEGIN
        SELECT gra.sp_verifica_disciplina_curso_ferias(
                       rec_aluno.pessoa,
                       par_disciplina::INTEGER)
        INTO bool_podecursar;
    EXCEPTION
        WHEN OTHERS THEN
            rec_retorno.erro := FALSE;
            rec_retorno.cumpriu := FALSE;
            rec_retorno.textolivre := 'O aluno não pode cursar a disciplina "' || rec_disciplina.nome || '" (#02).';
            RAISE NOTICE '=================> ERRO:%', rec_retorno;
            RAISE NOTICE '% %', sqlerrm, sqlstate;
            RETURN NEXT rec_retorno; RETURN;
    END;

    bool_disciplina_institucional := FALSE;
    --bool_disciplina_institucional := SUBSTRING(rec_prequisitos.disciplina_label, 1, 4) = 'GINS';

    RAISE NOTICE '==> bool_disciplina_institucional : %',bool_disciplina_institucional;
    RAISE NOTICE '==> bool_podecursar               : %',bool_podecursar;

    /*
    IF bool_disciplina_institucional AND NOT bool_podecursar THEN
        rec_retorno.erro := FALSE;
        rec_retorno.cumpriu := FALSE;
        rec_retorno.textolivre := 'O aluno não pode cursar a disciplina "' || rec_disciplina.nome || '" (#03).';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;
    */

    IF bool_disciplina_institucional --AND bool_podecursar
        AND num_disciplinas_institucionais >= num_max_disciplinas_institucionais THEN
        rec_retorno.erro := FALSE;
        rec_retorno.cumpriu := FALSE;
        rec_retorno.textolivre := 'O aluno não pode cursar a disciplina "' || rec_disciplina.nome || '" (#04).';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;

    IF NOT bool_disciplina_institucional AND bool_podecursar
        AND num_disciplinas_naoinstitucionais_sem_quebra >= num_max_disciplinas_naoinstitucionais_sem_quebra THEN
        rec_retorno.erro := FALSE;
        rec_retorno.cumpriu := FALSE;
        rec_retorno.textolivre := 'O aluno não pode cursar a disciplina "' || rec_disciplina.nome || '" (#05).';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;

    IF NOT bool_disciplina_institucional AND NOT bool_podecursar
        AND num_disciplinas_naoinstitucionais_com_quebra >= num_max_disciplinas_naoinstitucionais_com_quebra THEN
        rec_retorno.erro := FALSE;
        rec_retorno.cumpriu := FALSE;
        rec_retorno.textolivre := 'O aluno não pode cursar a disciplina "' || rec_disciplina.nome || '" (#06).';
        RAISE NOTICE '=================> ERRO:%', rec_retorno;
        RETURN NEXT rec_retorno; RETURN;
    END IF;
    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    rec_retorno.erro := FALSE;
    rec_retorno.cumpriu := TRUE;
    rec_retorno.textolivre := NULL;
    RETURN NEXT rec_retorno; RETURN;
    ----------------------------------------------------------------------------------------------------------------

END
$$;
